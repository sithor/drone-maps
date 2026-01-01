// Memory management and crash prevention
let isLoading = false;
let loadingAbortController = null;

// Survey area configuration
const surveyCenter = [-36.8830, 174.7804]; // Survey area center
const kmOffset = 1.5 / 111; // 1.5km in each direction = 3km total

// Initialize the map with better error handling
let map;
try {
    // Restrict map to 3km area around survey site
    const restrictedBounds = [
        [surveyCenter[0] - kmOffset, surveyCenter[1] - kmOffset],  // Southwest
        [surveyCenter[0] + kmOffset, surveyCenter[1] + kmOffset]   // Northeast
    ];
    
    map = L.map('map', {
        center: surveyCenter,
        zoom: 16,
        minZoom: 13,
        maxZoom: 22,
        zoomControl: true,
        preferCanvas: true,
        maxBounds: restrictedBounds,
        maxBoundsViscosity: 1.0,
        renderer: L.canvas()
    });
    
    console.log('Map initialized with 3km restricted bounds:', restrictedBounds);
} catch (error) {
    console.error('Failed to initialize map:', error);
    showError('Failed to initialize the map viewer. Please refresh the page.');
}

// Add a base tile layer (OpenStreetMap) with strict limits
const baseLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 22, // Match map maxZoom
    maxNativeZoom: 19,
    keepBuffer: 2, // Limit tile buffer to reduce memory
    updateWhenIdle: true, // Only update tiles when map stops moving
    updateWhenZooming: false // Don't update while zooming
}).addTo(map);

let orthophotoLayer = null;
let demGeoRaster = null; // For elevation data
const loadingElement = document.getElementById('loading');
const opacitySlider = document.getElementById('opacity-slider');
const opacityValue = document.getElementById('opacity-value');
const toggleLayerCheckbox = document.getElementById('toggle-layer');

// Measurement variables
let measurementLayer = new L.FeatureGroup();
map.addLayer(measurementLayer);
let currentMeasurementMode = null;
let measurementMarkers = [];
let measurementLines = [];

const measureDistanceBtn = document.getElementById('measure-distance');
const measureAreaBtn = document.getElementById('measure-area');
const clearMeasurementsBtn = document.getElementById('clear-measurements');
const measurementResult = document.getElementById('measurement-result');

// Enhanced error handling function
function showError(message, recoverable = true) {
    loadingElement.style.display = 'none';
    isLoading = false;
    
    // Clean up any existing error messages
    const existingErrors = document.querySelectorAll('.error');
    existingErrors.forEach(error => error.remove());
    
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error';
    errorDiv.innerHTML = `
        <strong>⚠️ Application Error</strong><br>
        ${message}<br><br>
        ${recoverable ? '<button onclick="location.reload()" class="retry-btn">🔄 Retry</button>' : ''}
        <button onclick="this.parentElement.remove()" class="close-btn">✕ Close</button>
    `;
    document.body.appendChild(errorDiv);
    
    // Auto-hide after 10 seconds for non-critical errors
    if (recoverable) {
        setTimeout(() => {
            if (errorDiv.parentElement) {
                errorDiv.remove();
            }
        }, 10000);
    }
}

// Memory-conscious orthophoto loading with crash prevention
async function loadOrthophoto() {
    // Prevent multiple simultaneous loading attempts
    if (isLoading) {
        console.log('Loading already in progress, skipping...');
        return;
    }
    
    isLoading = true;
    loadingAbortController = new AbortController();
    
    try {
        // Clean up existing layer to free memory
        if (orthophotoLayer) {
            map.removeLayer(orthophotoLayer);
            orthophotoLayer = null;
        }
        
        loadingElement.style.display = 'block';
        loadingElement.textContent = 'Loading orthophoto...';
        
        // Load DEM for 3D measurements
        await loadDEM();
        
        // Try web-optimized version first to prevent crashes/memory issues
        const orthophotoUrls = [
            'all/odm_orthophoto/odm_orthophoto_web.tif',
            'all/odm_orthophoto/odm_orthophoto.tif',
            'all/odm_orthophoto/odm_orthophoto_original.tif'
        ];
        
        let response = null;
        let usedUrl = null;
        
        for (const url of orthophotoUrls) {
            try {
                // Add cache buster to force fresh download
                const cacheBuster = `?t=${Date.now()}`;
                const fetchUrl = url + cacheBuster;
                console.log(`Attempting to load: ${url} (with cache buster)`);
                response = await fetch(fetchUrl, {
                    signal: loadingAbortController.signal,
                    headers: {
                        'Cache-Control': 'no-cache, no-store, must-revalidate',
                        'Pragma': 'no-cache',
                        'Expires': '0'
                    }
                });
                
                if (response.ok) {
                    usedUrl = url;
                    break;
                }
            } catch (fetchError) {
                console.warn(`Failed to fetch ${url}:`, fetchError.message);
                continue;
            }
        }
        
        if (!response || !response.ok) {
            throw new Error('No orthophoto file found. Please run the optimization script first.');
        }
        
        console.log(`Successfully loading from: ${usedUrl}`);
        
        // Check file size before proceeding
        const contentLength = response.headers.get('Content-Length');
        if (contentLength) {
            const sizeMB = parseInt(contentLength) / (1024 * 1024);
            console.log(`File size: ${sizeMB.toFixed(1)} MB`);
            
            if (sizeMB > 200) {
                throw new Error(`File too large (${sizeMB.toFixed(1)} MB). Please run the downsizing script first.`);
            }
        }
        
        loadingElement.textContent = 'Downloading image data...';
        const arrayBuffer = await response.arrayBuffer();
        
        if (loadingAbortController.signal.aborted) {
            throw new Error('Loading was cancelled');
        }
        
        loadingElement.textContent = 'Processing image...';
        
        // Parse with memory limits
        const georaster = await parseGeoraster(arrayBuffer);
        
        if (!georaster) {
            throw new Error('Failed to parse GeoTIFF data');
        }
        
        console.log('GeoTIFF info:', {
            width: georaster.width,
            height: georaster.height,
            bands: georaster.numberOfRasters,
            bounds: [georaster.xmin, georaster.ymin, georaster.xmax, georaster.ymax]
        });
        
        loadingElement.textContent = 'Rendering map layer...';
        
        // Create layer with maximum quality settings
        orthophotoLayer = new GeoRasterLayer({
            georaster: georaster,
            opacity: 1,
            resolution: 1024, // Maximum resolution for best quality
            debugLevel: 0, // Disable debug logging
            updateWhenZooming: false, // Don't update while zooming for performance
            updateWhenIdle: true, // Update when idle for quality
            pixelValuesToColorFn: function(pixelValues) {
                try {
                    // For RGB imagery
                    if (pixelValues && pixelValues.length >= 3) {
                        const [r, g, b] = pixelValues;
                        // Handle NoData values
                        if ((r === 0 && g === 0 && b === 0) || 
                            r > 255 || g > 255 || b > 255 || 
                            r < 0 || g < 0 || b < 0) {
                            return null; // Transparent
                        }
                        return `rgb(${Math.round(r)}, ${Math.round(g)}, ${Math.round(b)})`;
                    }
                    // For grayscale
                    const value = pixelValues[0];
                    if (value === 0 || value > 255 || value < 0) return null;
                    return `rgb(${Math.round(value)}, ${Math.round(value)}, ${Math.round(value)})`;
                } catch (error) {
                    return null; // Fallback for any pixel processing errors
                }
            }
        });
        
        orthophotoLayer.addTo(map);
        
        // Zoom to survey center instead of fitting bounds (which might zoom out too far)
        map.setView(surveyCenter, 18);
        
        console.log('✅ Orthophoto loaded - staying within 3km boundary');
        
        loadingElement.style.display = 'none';
        isLoading = false;
        
        console.log('✅ Orthophoto loaded successfully!');
        
        // Update UI elements
        toggleLayerCheckbox.checked = true;
        
        // Monitor zoom level to warn users
        map.on('zoomend', function() {
            const currentZoom = map.getZoom();
            if (currentZoom > 20) {
                console.warn('Very high zoom level detected:', currentZoom);
                showError('Very high zoom level may impact performance on some devices.', true);
            }
        });
        
    } catch (error) {
        isLoading = false;
        console.error('❌ Error loading orthophoto:', error);
        
        let errorMessage = error.message;
        
        if (error.name === 'AbortError') {
            errorMessage = 'Loading was cancelled';
        } else if (error.message.includes('fetch')) {
            errorMessage = `Network error: ${error.message}<br><br>
                <strong>Troubleshooting:</strong><br>
                1. Make sure you're running a web server<br>
                2. Check if the orthophoto files exist<br>
                3. Run the optimization script: <code>./setup_and_optimize.sh</code>`;
        } else if (error.message.includes('too large')) {
            errorMessage = `${error.message}<br><br>
                <strong>Fix:</strong> Run <code>python3 downsize_orthophoto.py</code> to create a smaller version.`;
        }
        
        showError(`Failed to load orthophoto:<br><br>${errorMessage}`);
    } finally {
        loadingElement.style.display = 'none';
        isLoading = false;
        loadingAbortController = null;
    }
}

// Load Digital Elevation Model for 3D measurements
async function loadDEM() {
    try {
        console.log('Loading DEM for terrain-aware measurements...');
        
        // Try web-optimized version first, then fall back to original
        const demUrls = [
            'all/odm_dem/dsm_web.tif',
            'all/odm_dem/dsm.tif'
        ];
        
        let demResponse = null;
        let usedUrl = null;
        
        for (const url of demUrls) {
            try {
                console.log(`Trying ${url}...`);
                demResponse = await fetch(url, {
                    headers: {
                        'Cache-Control': 'no-cache'
                    }
                });
                
                if (demResponse.ok) {
                    usedUrl = url;
                    console.log(`✓ Found DEM at ${url}`);
                    break;
                }
            } catch (e) {
                console.log(`✗ ${url} not available`);
            }
        }
        
        if (!demResponse || !demResponse.ok) {
            console.warn('⚠️ No DEM file found - measurements will be 2D only');
            console.warn('Run: python3 downsize_dem.py to create web-optimized DEM');
            return;
        }
        
        // Check DEM size
        const contentLength = demResponse.headers.get('Content-Length');
        if (contentLength) {
            const sizeMB = parseInt(contentLength) / (1024 * 1024);
            console.log(`DEM file size: ${sizeMB.toFixed(1)} MB`);
            
            if (sizeMB > 100) {
                console.warn('⚠️ DEM is very large, may take time to load');
            }
        }
        
        const demArrayBuffer = await demResponse.arrayBuffer();
        demGeoRaster = await parseGeoraster(demArrayBuffer);
        
        if (!demGeoRaster) {
            throw new Error('Failed to parse DEM');
        }
        
        console.log('✅ DEM loaded successfully - 3D measurements enabled');
        console.log('DEM info:', {
            width: demGeoRaster.width,
            height: demGeoRaster.height,
            bands: demGeoRaster.numberOfRasters,
            xmin: demGeoRaster.xmin,
            xmax: demGeoRaster.xmax,
            ymin: demGeoRaster.ymin,
            ymax: demGeoRaster.ymax,
            pixelWidth: demGeoRaster.pixelWidth,
            pixelHeight: demGeoRaster.pixelHeight,
            projection: demGeoRaster.projection
        });
        
        // Check coordinate system
        const coordsLookProjected = Math.abs(demGeoRaster.xmin) > 360;
        console.log('Coordinate system:', coordsLookProjected ? '⚠️ PROJECTED (will try to use anyway)' : '✓ GEOGRAPHIC (lat/lng)');
        demGeoRaster.isProjected = coordsLookProjected;
        
        // Don't reject - we'll try to use it anyway
        
        // Sample elevation values to verify data
        console.log('Sampling DEM values...');
        const sampleVals = [];
        for (let i = 0; i < Math.min(10, demGeoRaster.height); i += 2) {
            for (let j = 0; j < Math.min(10, demGeoRaster.width); j += 2) {
                const val = demGeoRaster.values[0][i][j];
                if (val !== null && val !== undefined && !isNaN(val)) {
                    sampleVals.push(val);
                }
            }
        }
        if (sampleVals.length > 0) {
            console.log(`Sampled ${sampleVals.length} valid elevation values`);
            console.log('Min elevation:', Math.min(...sampleVals).toFixed(2), 'm');
            console.log('Max elevation:', Math.max(...sampleVals).toFixed(2), 'm');
            console.log('Range:', (Math.max(...sampleVals) - Math.min(...sampleVals)).toFixed(2), 'm');
        } else {
            console.error('❌ No valid elevation values found in DEM!');
        }
        
    } catch (error) {
        console.error('Could not load DEM:', error);
        console.warn('Measurements will be 2D only (no elevation data)');
        demGeoRaster = null;
    }
}

// Get elevation at a specific lat/lng point
function getElevation(latlng) {
    if (!demGeoRaster) {
        return 0;
    }
    
    try {
        const x = latlng.lng;
        const y = latlng.lat;
        
        console.log(`Getting elevation for: lat=${y.toFixed(6)}, lng=${x.toFixed(6)}`);
        console.log(`DEM bounds: x=[${demGeoRaster.xmin}, ${demGeoRaster.xmax}], y=[${demGeoRaster.ymin}, ${demGeoRaster.ymax}]`);
        
        // Check if point is within DEM bounds
        if (x < demGeoRaster.xmin || x > demGeoRaster.xmax ||
            y < demGeoRaster.ymin || y > demGeoRaster.ymax) {
            console.warn(`❌ Point OUTSIDE DEM bounds`);
            return 0;
        }
        
        // Convert geographic coordinates to pixel coordinates
        const pixelX = Math.floor((x - demGeoRaster.xmin) / demGeoRaster.pixelWidth);
        const pixelY = Math.floor((demGeoRaster.ymax - y) / demGeoRaster.pixelHeight);
        
        console.log(`Pixel coordinates: x=${pixelX}, y=${pixelY} (DEM size: ${demGeoRaster.width}x${demGeoRaster.height})`);
        
        // Ensure pixel coordinates are within bounds
        if (pixelX < 0 || pixelX >= demGeoRaster.width || 
            pixelY < 0 || pixelY >= demGeoRaster.height) {
            console.warn(`❌ Pixel coords OUT OF RANGE`);
            return 0;
        }
        
        // Get elevation value
        const elevation = demGeoRaster.values[0][pixelY][pixelX];
        
        if (elevation === null || elevation === undefined || isNaN(elevation)) {
            console.warn(`❌ No valid elevation at pixel (${pixelX}, ${pixelY})`);
            return 0;
        }
        
        console.log(`✅ Elevation: ${elevation.toFixed(2)} m`);
        return elevation;
        
    } catch (error) {
        console.error('❌ Error getting elevation:', error);
        return 0;
    }
}

// Calculate 3D distance between two points considering elevation
function calculate3DDistance(latlng1, latlng2) {
    // Get 2D horizontal distance
    const horizontalDistance = map.distance(latlng1, latlng2);
    
    // Get elevations
    const elev1 = getElevation(latlng1);
    const elev2 = getElevation(latlng2);
    const elevDiff = elev2 - elev1;
    
    console.log(`Distance calc: H=${horizontalDistance.toFixed(2)}m, Elev1=${elev1.toFixed(2)}m, Elev2=${elev2.toFixed(2)}m, Diff=${elevDiff.toFixed(2)}m`);
    
    // Calculate 3D distance using Pythagorean theorem
    const distance3D = Math.sqrt(horizontalDistance * horizontalDistance + elevDiff * elevDiff);
    
    return {
        horizontal: horizontalDistance,
        vertical: elevDiff,
        distance3D: distance3D,
        hasElevation: demGeoRaster !== null && (elev1 !== 0 || elev2 !== 0)
    };
}

// Opacity control
opacitySlider.addEventListener('input', (e) => {
    const opacity = e.target.value / 100;
    opacityValue.textContent = e.target.value;
    if (orthophotoLayer) {
        orthophotoLayer.setOpacity(opacity);
    }
});

// Toggle layer visibility
toggleLayerCheckbox.addEventListener('change', (e) => {
    if (orthophotoLayer) {
        if (e.target.checked) {
            map.addLayer(orthophotoLayer);
        } else {
            map.removeLayer(orthophotoLayer);
        }
    }
});

// Measurement tools
function formatDistance(meters) {
    if (meters < 1000) {
        return `${meters.toFixed(2)} m`;
    }
    return `${(meters / 1000).toFixed(2)} km`;
}

function formatArea(squareMeters) {
    if (squareMeters < 10000) {
        return `${squareMeters.toFixed(2)} m²`;
    }
    return `${(squareMeters / 10000).toFixed(2)} hectares`;
}

function clearMeasurements() {
    measurementLayer.clearLayers();
    measurementMarkers = [];
    measurementLines = [];
    measurementResult.style.display = 'none';
    measurementResult.innerHTML = '';
    currentMeasurementMode = null;
    measureDistanceBtn.classList.remove('active');
    measureAreaBtn.classList.remove('active');
    map.off('click', measurementClickHandler);
}

function measurementClickHandler(e) {
    if (!currentMeasurementMode) return;
    
    const marker = L.circleMarker(e.latlng, {
        radius: 5,
        color: '#3b82f6',
        fillColor: '#3b82f6',
        fillOpacity: 0.8
    }).addTo(measurementLayer);
    
    measurementMarkers.push(e.latlng);
    
    if (currentMeasurementMode === 'distance') {
        measureDistance();
    } else if (currentMeasurementMode === 'area') {
        measureArea();
    }
}

function measureDistance() {
    if (measurementMarkers.length < 2) {
        measurementResult.style.display = 'block';
        measurementResult.innerHTML = `Click on the map to place points. ${measurementMarkers.length}/2 points placed.`;
        return;
    }
    
    // Remove old lines
    measurementLines.forEach(line => measurementLayer.removeLayer(line));
    measurementLines = [];
    
    // Calculate total distance (both 2D and 3D)
    let totalDistance2D = 0;
    let totalDistance3D = 0;
    let totalElevGain = 0;
    let totalElevLoss = 0;
    
    for (let i = 0; i < measurementMarkers.length - 1; i++) {
        const result = calculate3DDistance(measurementMarkers[i], measurementMarkers[i + 1]);
        totalDistance2D += result.horizontal;
        totalDistance3D += result.distance3D;
        
        if (result.vertical > 0) {
            totalElevGain += result.vertical;
        } else {
            totalElevLoss += Math.abs(result.vertical);
        }
        
        // Draw line segment
        const line = L.polyline([measurementMarkers[i], measurementMarkers[i + 1]], {
            color: '#3b82f6',
            weight: 3,
            opacity: 0.7
        }).addTo(measurementLayer);
        measurementLines.push(line);
    }
    
    measurementResult.style.display = 'block';
    
    if (demGeoRaster) {
        measurementResult.innerHTML = `
            <strong>3D Distance:</strong> ${formatDistance(totalDistance3D)}<br>
            <strong>2D Distance:</strong> ${formatDistance(totalDistance2D)}<br>
            <strong>Elevation Gain:</strong> ${totalElevGain.toFixed(2)} m ⬆️<br>
            <strong>Elevation Loss:</strong> ${totalElevLoss.toFixed(2)} m ⬇️<br>
            <small>Points: ${measurementMarkers.length} | Click to add more or press Clear to finish</small>
        `;
    } else {
        measurementResult.innerHTML = `
            <strong>Distance:</strong> ${formatDistance(totalDistance2D)}<br>
            <small>Points: ${measurementMarkers.length} | 2D only (no elevation data)</small>
        `;
    }
}

function measureArea() {
    if (measurementMarkers.length < 3) {
        measurementResult.style.display = 'block';
        measurementResult.innerHTML = `Click on the map to place points. ${measurementMarkers.length}/3+ points placed.`;
        return;
    }
    
    // Remove old polygon
    measurementLines.forEach(line => measurementLayer.removeLayer(line));
    measurementLines = [];
    
    // Draw polygon
    const polygon = L.polygon(measurementMarkers, {
        color: '#16a34a',
        fillColor: '#16a34a',
        fillOpacity: 0.3,
        weight: 3
    }).addTo(measurementLayer);
    measurementLines.push(polygon);
    
    // Calculate 2D area using Leaflet's built-in method
    const area2D = L.GeometryUtil.geodesicArea(measurementMarkers);
    
    // Calculate perimeter (both 2D and 3D)
    let perimeter2D = 0;
    let perimeter3D = 0;
    for (let i = 0; i < measurementMarkers.length; i++) {
        const next = (i + 1) % measurementMarkers.length;
        const result = calculate3DDistance(measurementMarkers[i], measurementMarkers[next]);
        perimeter2D += result.horizontal;
        perimeter3D += result.distance3D;
    }
    
    // Calculate average elevation
    let avgElevation = 0;
    if (demGeoRaster) {
        let totalElev = 0;
        measurementMarkers.forEach(marker => {
            totalElev += getElevation(marker);
        });
        avgElevation = totalElev / measurementMarkers.length;
    }
    
    measurementResult.style.display = 'block';
    
    if (demGeoRaster) {
        measurementResult.innerHTML = `
            <strong>Area (2D):</strong> ${formatArea(area2D)}<br>
            <strong>Perimeter (3D):</strong> ${formatDistance(perimeter3D)}<br>
            <strong>Perimeter (2D):</strong> ${formatDistance(perimeter2D)}<br>
            <strong>Avg Elevation:</strong> ${avgElevation.toFixed(2)} m<br>
            <small>Points: ${measurementMarkers.length} | Click to add more</small>
        `;
    } else {
        measurementResult.innerHTML = `
            <strong>Area:</strong> ${formatArea(area2D)}<br>
            <strong>Perimeter:</strong> ${formatDistance(perimeter2D)}<br>
            <small>Points: ${measurementMarkers.length} | 2D only (no elevation data)</small>
        `;
    }
}

measureDistanceBtn.addEventListener('click', () => {
    clearMeasurements();
    currentMeasurementMode = 'distance';
    measureDistanceBtn.classList.add('active');
    measurementResult.style.display = 'block';
    
    // Debug DEM status
    if (demGeoRaster) {
        console.log('✅ DEM is loaded and ready for 3D measurements');
        console.log('DEM bounds:', {
            x: [demGeoRaster.xmin, demGeoRaster.xmax],
            y: [demGeoRaster.ymin, demGeoRaster.ymax],
            isProjected: demGeoRaster.isProjected
        });
        measurementResult.innerHTML = `Click on the map to start measuring distance. (3D mode enabled)<br><small>DEM: ${demGeoRaster.width}x${demGeoRaster.height}, bounds: ${demGeoRaster.xmin.toFixed(2)} to ${demGeoRaster.xmax.toFixed(2)}</small>`;
    } else {
        console.warn('⚠️ DEM is NOT loaded - measurements will be 2D only');
        measurementResult.innerHTML = 'Click on the map to start measuring distance. (2D mode - no elevation data)';
    }
    
    map.on('click', measurementClickHandler);
});

measureAreaBtn.addEventListener('click', () => {
    clearMeasurements();
    currentMeasurementMode = 'area';
    measureAreaBtn.classList.add('active');
    measurementResult.style.display = 'block';
    
    // Debug DEM status
    if (demGeoRaster) {
        console.log('✅ DEM is loaded and ready for 3D measurements');
        measurementResult.innerHTML = 'Click on the map to start measuring area (minimum 3 points). (3D mode enabled)';
    } else {
        console.warn('⚠️ DEM is NOT loaded - measurements will be 2D only');
        measurementResult.innerHTML = 'Click on the map to start measuring area (minimum 3 points). (2D mode - no elevation data)';
    }
    
    map.on('click', measurementClickHandler);
});

clearMeasurementsBtn.addEventListener('click', () => {
    clearMeasurements();
});

// Add Leaflet GeometryUtil for area calculation
L.GeometryUtil = L.extend(L.GeometryUtil || {}, {
    geodesicArea: function (latLngs) {
        const pointsCount = latLngs.length;
        let area = 0.0;
        const d2r = Math.PI / 180;
        const p1 = latLngs[0];
        
        if (pointsCount > 2) {
            for (let i = 1; i < pointsCount; i++) {
                const p2 = latLngs[i];
                const p3 = latLngs[(i + 1) % pointsCount];
                area += (d2r * (p3.lng - p1.lng)) * (2 + Math.sin(d2r * p2.lat) + Math.sin(d2r * p3.lat));
            }
            area = area * 6378137.0 * 6378137.0 / 2.0;
        }
        
        return Math.abs(area);
    }
});

// Load the orthophoto when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Check if required libraries are loaded
    const requiredLibraries = [
        { name: 'Leaflet', check: () => typeof L !== 'undefined' },
        { name: 'parseGeoraster', check: () => typeof parseGeoraster === 'function' },
        { name: 'GeoRasterLayer', check: () => typeof GeoRasterLayer !== 'undefined' }
    ];
    
    const missingLibraries = requiredLibraries.filter(lib => !lib.check());
    
    if (missingLibraries.length > 0) {
        const libraryNames = missingLibraries.map(lib => lib.name).join(', ');
        showError(`Required libraries not loaded: ${libraryNames}<br><br>
            This may be due to:<br>
            1. Network connectivity issues<br>
            2. CDN service problems<br>
            3. Browser compatibility issues<br><br>
            Try refreshing the page or checking your internet connection.`);
        return;
    }
    
    // Initialize application if all libraries are loaded
    try {
        if (map && typeof loadOrthophoto === 'function') {
            loadOrthophoto();
        } else {
            showError('Map initialization failed. Please refresh the page.');
        }
    } catch (error) {
        console.error('Initialization error:', error);
        showError(`Application initialization failed: ${error.message}`);
    }
});

// Fallback: try to load after 2 seconds if DOMContentLoaded already fired
setTimeout(function() {
    if (document.readyState === 'complete' && !isLoading && !orthophotoLayer) {
        console.log('Attempting delayed initialization...');
        if (typeof loadOrthophoto === 'function' && map) {
            loadOrthophoto();
        }
    }
}, 2000);
