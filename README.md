# JIIMPS: Augmented Reality for Architecture

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2022b%2B-blue.svg)](https://www.mathworks.com/products/matlab.html)

## About the Project
This project brings 2D architectural floor plans to life using Augmented Reality (AR). By leveraging computer vision and image processing techniques in MATLAB, the system processes a live video stream of a 2D floor plan (drawn or printed on paper) and augments it with a perspective-correct 3D representation of the structure. It automatically detects walls, rooms, and text dimensions, extracting structured data from a simple 2D drawing and instantly visualizing it as a 3D model on top of the physical paper.

## Impact on the World
Architecture and construction industries rely heavily on 2D blueprints, which can be difficult for clients and non-experts to visualize in 3D space. **JIIMPS** bridges this gap by offering an intuitive, real-time AR visualization tool. It democratizes architectural understanding, reduces miscommunications during the design phase, and accelerates decision-making. By seamlessly transforming flat drawings into immersive 3D models, this technology empowers architects, builders, and homeowners to explore physical spaces before they are built, saving time, reducing costly revisions, and enhancing collaborative design.

## Use Cases
- **Architectural Visualization:** Presenting designs to clients by simply pointing a camera at a blueprint, instantly showing them the 3D volume of the space.
- **Construction & Planning:** Helping contractors visualize wall heights, room layouts, and dimension constraints directly on site.
- **Real Estate:** Allowing potential buyers to visualize 2D floor plans of unbuilt properties in 3D AR.
- **Education:** Teaching spatial reasoning and architectural design to students by dynamically bringing their sketches to life.

## Architecture and Workflow
The system pipeline operates in the following stages:
1. **Camera Calibration:** Extracts intrinsic camera parameters using a checkerboard pattern to ensure accurate 3D projections.
2. **Pose Estimation:** Detects an AprilTag placed on the floor plan to calculate the real-time 3D pose (position and orientation) of the camera relative to the paper.
3. **Feature Detection:**
   - **Walls:** Uses edge detection (Canny) and Hough Transforms to find line segments representing walls.
   - **Rooms:** Uses connected component analysis to segment enclosed spaces (background is automatically excluded).
   - **Text:** Uses Optical Character Recognition (OCR) to extract dimension text (noise tokens < 2 chars are filtered).
4. **AR Augmentation:** Projects 3D geometry (e.g., extruded walls with transparency) onto the live video feed, dynamically updating as the camera moves.

## System Requirements
- **MATLAB R2022b or later** (Required for the newest `readAprilTag` and `world2img` APIs)
- **Computer Vision Toolbox** (Essential for camera parameters and AprilTag detection)
- **Image Processing Toolbox** (Essential for wall and room detection)
- *(Optional)* **Deep Learning Toolbox** & YOLO v4 Add-on (For advanced furniture symbol detection)

## Files and Code Structure
| File | Description | Assignment Requirement |
|---|---|---|
| `detectWalls.m` | Detects wall segments using Hough Transform (preallocated struct) | Detect relevant floor plan features |
| `detectRooms.m` | Segments rooms using connected components; filters background blob via `MaxArea` | Advanced: additional information |
| `extractDimensionText.m` | Extracts wall length labels via OCR; filters blank/noise tokens via `MinLength` | Advanced: auto measurement |
| `detectFurniture.m` | Detects furniture symbols with a YOLO detector (preallocated struct) | Advanced: symbol detection |
| `estimatePoseFromTag.m` | Calculates camera pose using AprilTag | Determine pose using known features |
| `renderARWalls.m` | Draws the 3D perspective-correct overlay | Augment video with 3D representation |
| `floorplan_AR_main.m` | Core pipeline for static images + JSON export | Core detection logic |
| `liveARDemo.m` | Real-time AR overlay using a live webcam feed | Run in real-time on video feed |
| `makeDummyCameraParams.m` | Generates a placeholder `cameraParams.mat` for testing without real calibration | Testing utility |
| `generateTestFloorplan.m` | Generates `test_floorplan.png` with a real embedded AprilTag (tag36h11 id=0) | Test data generation |

## Setup and Usage
1. **Calibrate Camera:** Print a checkerboard, take 15-20 photos with your webcam, run the Camera Calibrator App in MATLAB, and export the parameters as `cameraParams.mat`.
   - *Quick test without calibration:* Run `makeDummyCameraParams.m` to generate a placeholder `cameraParams.mat`.
2. **Prepare Floor Plan:** Use the included `test_floorplan.png` (already contains an embedded **AprilTag tag36h11 id=0**), or regenerate it by running `generateTestFloorplan.m`. To use your own floor plan, print it and tape a **tag36h11** AprilTag at a known location.
3. **Extract Data:** Run `floorplan_AR_main.m` to generate `floorplan_output.json` and `referenceFloorplan.mat`.
4. **Run Live AR:** Run `liveARDemo.m`, point your webcam at the floor plan, and watch the 3D walls rise from the paper!

## Key Improvements (v2)
| Issue | Fix Applied |
|---|---|
| Background blob detected as `Room_0` (area ≈ entire image) | `detectRooms` now auto-excludes the largest connected component via `MaxArea` |
| OCR noise tokens (blank/whitespace, single char) in output | `extractDimensionText` filters tokens with `strtrim` length < `MinLength` (default 2) |
| Struct arrays grown dynamically in loops (`%#ok<AGROW>`) | `detectWalls`, `detectRooms`, `extractDimensionText`, `detectFurniture` now preallocate |
| No LICENSE file | MIT License added to repository root |
| `test_floorplan.png` had only a placeholder square, not a real AprilTag | `generateTestFloorplan.m` embeds a proper tag36h11 id=0 bit-pattern |

## License
This project is licensed under the [MIT License](LICENSE).
