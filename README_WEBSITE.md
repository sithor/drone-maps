# Drone Mapping Website

This website displays the orthographic map output from WebODM.

## Features

- Interactive map viewer using Leaflet
- Displays the GeoTIFF orthophoto from WebODM
- Opacity control for the orthophoto layer
- Toggle orthophoto visibility
- Base map from OpenStreetMap for reference

## Running the Website

Since the website loads GeoTIFF files, you need to run it through a local web server (not by opening the HTML file directly in a browser due to CORS restrictions).

### Option 1: Using Python (Recommended)

```bash
cd /workspaces/drone-maps
python3 -m http.server 8000
```

Then open your browser to: `http://localhost:8000`

### Option 2: Using Node.js (http-server)

```bash
npx http-server -p 8000
```

### Option 3: Using PHP

```bash
php -S localhost:8000
```

## Files Structure

```
/workspaces/drone-maps/
├── index.html          # Main HTML file
├── app.js              # JavaScript application code
├── all/                # WebODM output directory
│   └── odm_orthophoto/
│       └── odm_orthophoto.tif  # The orthographic map
```

## Technologies Used

- **Leaflet**: Interactive map library
- **GeoTIFF.js**: For reading GeoTIFF files
- **Georaster**: For parsing georeferenced rasters
- **Georaster Layer for Leaflet**: For displaying georasters on Leaflet maps
- **OpenStreetMap**: Base map tiles

## Next Steps

You can extend this website to include:
- Digital Elevation Model (DEM) visualization
- 3D point cloud viewer
- Multiple layer switching
- Measurement tools
- Download options
- Comparison tools
