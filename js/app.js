// Drone Maps Viewer Application
// Handles orthographic maps and 3D models from webODM

// Global variables
let map = null;
let scene, camera, renderer, controls;
let currentModel = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
    initializeTabs();
    initializeMap();
    loadSavedConfig();
});

// Tab Management
function initializeTabs() {
    const tabButtons = document.querySelectorAll('.tab-button');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const tabName = button.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
}

function switchTab(tabName) {
    // Update button states
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    // Update content visibility
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    // Handle tab-specific initialization
    if (tabName === 'models' && !scene) {
        initialize3DViewer();
    }
}

// Map Initialization and Management
function initializeMap() {
    // Initialize empty map centered on world view
    map = L.map('map', {
        center: [0, 0],
        zoom: 2,
        minZoom: 1,
        maxZoom: 22
    });
    
    // Add a default base layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
    }).addTo(map);
    
    document.getElementById('map').classList.add('initialized');
    
    // Update map info
    updateMapInfo('OpenStreetMap base layer loaded. Add webODM orthophoto tiles to view your maps.');
}

function loadMapTiles() {
    const tileUrl = document.getElementById('tile-url').value.trim();
    
    if (!tileUrl) {
        showMessage('maps', 'Please enter a tile server URL', 'error');
        return;
    }
    
    try {
        // Remove existing orthophoto layers
        map.eachLayer(layer => {
            if (layer.options && layer.options.attribution && layer.options.attribution.includes('webODM')) {
                map.removeLayer(layer);
            }
        });
        
        // Add new orthophoto layer
        const orthophotoLayer = L.tileLayer(tileUrl, {
            attribution: 'webODM Orthophoto',
            maxZoom: 22,
            tileSize: 256
        });
        
        orthophotoLayer.addTo(map);
        
        // Update info
        updateMapInfo(`Orthophoto tiles loaded from: ${tileUrl}`);
        showMessage('maps', 'Map tiles loaded successfully!', 'success');
        
        // Try to fit bounds if possible
        // Note: In production, you should get bounds from webODM API
        // For now, zoom to a reasonable level and allow user to adjust
        map.setView([0, 0], 3);
        
    } catch (error) {
        console.error('Error loading map tiles:', error);
        showMessage('maps', `Error loading tiles: ${error.message}`, 'error');
    }
}

function updateMapInfo(info) {
    const mapInfo = document.getElementById('map-info');
    mapInfo.innerHTML = `<p>${info}</p>`;
}

// 3D Viewer Initialization and Management
function initialize3DViewer() {
    const container = document.getElementById('viewer-3d');
    
    // Scene setup
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x87CEEB); // Sky blue
    
    // Camera setup
    camera = new THREE.PerspectiveCamera(
        75,
        container.clientWidth / container.clientHeight,
        0.1,
        10000
    );
    camera.position.set(0, 50, 100);
    camera.lookAt(0, 0, 0);
    
    // Renderer setup
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.shadowMap.enabled = true;
    container.innerHTML = '';
    container.appendChild(renderer.domElement);
    container.classList.add('initialized');
    
    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(100, 100, 50);
    directionalLight.castShadow = true;
    scene.add(directionalLight);
    
    // Grid helper for reference
    const gridHelper = new THREE.GridHelper(200, 20, 0x000000, 0x444444);
    scene.add(gridHelper);
    
    // Axes helper
    const axesHelper = new THREE.AxesHelper(50);
    scene.add(axesHelper);
    
    // Controls (basic implementation - in production use OrbitControls)
    setupBasicControls();
    
    // Start animation loop
    animate();
    
    // Handle window resize
    window.addEventListener('resize', onWindowResize, false);
    
    updateModelInfo('3D viewer initialized. Load a model to begin.');
}

function setupBasicControls() {
    const container = document.getElementById('viewer-3d');
    let isDragging = false;
    let previousMousePosition = { x: 0, y: 0 };
    
    // Store camera's spherical coordinates for proper orbiting
    let cameraRadius = 150;
    let cameraTheta = Math.PI / 4; // Azimuthal angle
    let cameraPhi = Math.PI / 3;   // Polar angle
    let target = new THREE.Vector3(0, 0, 0);
    
    function updateCamera() {
        camera.position.x = target.x + cameraRadius * Math.sin(cameraPhi) * Math.cos(cameraTheta);
        camera.position.y = target.y + cameraRadius * Math.cos(cameraPhi);
        camera.position.z = target.z + cameraRadius * Math.sin(cameraPhi) * Math.sin(cameraTheta);
        camera.lookAt(target);
    }
    
    container.addEventListener('mousedown', (e) => {
        isDragging = true;
        previousMousePosition = { x: e.clientX, y: e.clientY };
    });
    
    container.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        
        const deltaX = e.clientX - previousMousePosition.x;
        const deltaY = e.clientY - previousMousePosition.y;
        
        if (e.buttons === 1) { // Left button - orbital rotation
            cameraTheta += deltaX * 0.01;
            cameraPhi = Math.max(0.1, Math.min(Math.PI - 0.1, cameraPhi - deltaY * 0.01));
            updateCamera();
        } else if (e.buttons === 2) { // Right button - pan
            const panSpeed = 0.3;
            const right = new THREE.Vector3();
            const up = new THREE.Vector3(0, 1, 0);
            camera.getWorldDirection(right);
            right.cross(up).normalize();
            
            target.addScaledVector(right, -deltaX * panSpeed);
            target.y -= deltaY * panSpeed;
            updateCamera();
        }
        
        previousMousePosition = { x: e.clientX, y: e.clientY };
    });
    
    container.addEventListener('mouseup', () => {
        isDragging = false;
    });
    
    container.addEventListener('wheel', (e) => {
        e.preventDefault();
        const zoomSpeed = 0.1;
        const direction = e.deltaY > 0 ? 1 : -1;
        cameraRadius = Math.max(10, Math.min(500, cameraRadius + direction * zoomSpeed * 10));
        updateCamera();
    });
    
    container.addEventListener('contextmenu', (e) => e.preventDefault());
    
    // Set initial camera position
    updateCamera();
}

function animate() {
    requestAnimationFrame(animate);
    
    // Rotate model slowly if loaded
    if (currentModel) {
        currentModel.rotation.y += 0.001;
    }
    
    renderer.render(scene, camera);
}

function onWindowResize() {
    const container = document.getElementById('viewer-3d');
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
}

function loadModel() {
    const modelUrl = document.getElementById('model-url').value.trim();
    
    if (!modelUrl) {
        showMessage('models', 'Please enter a model URL', 'error');
        return;
    }
    
    if (!scene) {
        initialize3DViewer();
    }
    
    showMessage('models', 'Loading model... This may take a moment.', 'info');
    
    // TODO: Implement actual model loaders (THREE.OBJLoader, THREE.PLYLoader, etc.)
    // Current implementation shows a sample terrain for demonstration purposes
    // For production use, integrate proper Three.js model loaders based on file extension
    loadSampleModel();
    updateModelInfo(`Model URL: ${modelUrl} (Note: Using sample geometry for demonstration)`);
    showMessage('models', 'Sample model loaded. For production use, implement proper model loaders.', 'info');
}

function loadModelFile(file) {
    if (!file) return;
    
    if (!scene) {
        initialize3DViewer();
    }
    
    showMessage('models', `Loading ${file.name}...`, 'info');
    
    const reader = new FileReader();
    
    reader.onload = function(e) {
        // TODO: Parse the file based on extension and use appropriate Three.js loader
        // Example: .obj -> OBJLoader, .ply -> PLYLoader, .las/.laz -> LASLoader
        // Current implementation shows a sample model for demonstration
        loadSampleModel();
        updateModelInfo(`File: ${file.name} (${formatBytes(file.size)}) - Using sample geometry for demonstration`);
        showMessage('models', 'Sample model loaded. Implement proper file parsers for production use.', 'info');
    };
    
    reader.readAsArrayBuffer(file);
}

function loadSampleModel() {
    // Remove existing model
    if (currentModel) {
        scene.remove(currentModel);
    }
    
    // Create a sample terrain-like mesh
    const geometry = new THREE.PlaneGeometry(100, 100, 50, 50);
    
    // Add some height variation to simulate terrain
    const vertices = geometry.attributes.position.array;
    for (let i = 0; i < vertices.length; i += 3) {
        vertices[i + 2] = Math.sin(vertices[i] * 0.1) * Math.cos(vertices[i + 1] * 0.1) * 10;
    }
    geometry.computeVertexNormals();
    
    const material = new THREE.MeshPhongMaterial({
        color: 0x3a8c3a,
        flatShading: false,
        side: THREE.DoubleSide
    });
    
    currentModel = new THREE.Mesh(geometry, material);
    currentModel.rotation.x = -Math.PI / 2;
    currentModel.receiveShadow = true;
    currentModel.castShadow = true;
    
    scene.add(currentModel);
    
    // Center camera on model
    camera.position.set(0, 80, 120);
    camera.lookAt(0, 0, 0);
}

function updateModelInfo(info) {
    const modelInfo = document.getElementById('model-info');
    modelInfo.innerHTML = `<p>${info}</p>`;
}

// Configuration Management
function saveConfig() {
    const config = {
        webodmUrl: document.getElementById('webodm-url').value.trim(),
        apiToken: document.getElementById('api-token').value.trim()
    };
    
    localStorage.setItem('droneMapConfig', JSON.stringify(config));
    showMessage('setup', 'Configuration saved successfully!', 'success');
}

function loadSavedConfig() {
    const saved = localStorage.getItem('droneMapConfig');
    if (saved) {
        try {
            const config = JSON.parse(saved);
            document.getElementById('webodm-url').value = config.webodmUrl || '';
            document.getElementById('api-token').value = config.apiToken || '';
        } catch (error) {
            console.error('Error loading saved config:', error);
        }
    }
}

// Utility Functions
function showMessage(tab, message, type = 'info') {
    const tabContent = document.getElementById(`${tab}-tab`);
    
    // Remove existing messages
    const existingMessages = tabContent.querySelectorAll('.message');
    existingMessages.forEach(msg => msg.remove());
    
    // Create new message
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}`;
    messageDiv.textContent = message;
    
    // Insert at the top of the tab content
    tabContent.insertBefore(messageDiv, tabContent.firstChild);
    
    // Auto-remove after 5 seconds for success/info messages
    if (type !== 'error') {
        setTimeout(() => {
            messageDiv.remove();
        }, 5000);
    }
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}
