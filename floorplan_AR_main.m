%% floorplan_AR_main.m
% Static-image pipeline: detects walls, rooms, furniture, and dimension
% text in a photographed/printed floor plan, then saves the results to
% floorplan_output.json (same schema as the Python reference script) and
% previews an AR overlay if an AprilTag is visible in the image.
%
% Run section-by-section (Ctrl+Enter) to inspect intermediate results.

clear; clc; close all;

%% 0. Configuration
imagePath   = "test_floorplan.png";
tagFamily   = "tag36h11";
tagSizeM    = 0.08;             % printed AprilTag side length, meters
calibFile   = "cameraParams.mat"; % output of the Camera Calibrator App

useFurnitureDetector = false;   % set true if you have a YOLO detector set up

%% 1. Load image
img = imread(imagePath);
figure('Name', 'Input floor plan'); imshow(img);

%% 2. Load camera calibration (from the Camera Calibrator App)
% In the app: Camera Calibrator > Export Camera Parameters, save as
% cameraParams.mat containing a variable named cameraParams.
if isfile(calibFile)
    S = load(calibFile);
    intrinsics = S.cameraParams.Intrinsics;
else
    warning(['No calibration file found (%s). AR pose/projection steps ' ...
        'will be skipped -- run the Camera Calibrator App first.'], calibFile);
    intrinsics = [];
end

%% 3. Detect walls (Hough line detection)
walls = detectWalls(img);

figure('Name', 'Detected walls'); imshow(img); hold on
for k = 1:numel(walls)
    plot([walls(k).start(1) walls(k).stop(1)], ...
         [walls(k).start(2) walls(k).stop(2)], 'g-', 'LineWidth', 2);
end
hold off

%% 4. Detect rooms (connected components on free space)
rooms = detectRooms(img);

figure('Name', 'Detected rooms'); imshow(img); hold on
for r = 1:numel(rooms)
    plot(rooms(r).centroidPixel(1), rooms(r).centroidPixel(2), ...
        'o', 'MarkerSize', 10, 'MarkerFaceColor', rooms(r).colorHex, ...
        'MarkerEdgeColor', 'k');
    text(rooms(r).centroidPixel(1) + 5, rooms(r).centroidPixel(2), ...
        rooms(r).id, 'Color', 'w', 'FontWeight', 'bold');
end
hold off

%% 5. Detect furniture symbols (optional, requires a trained/pretrained detector)
if useFurnitureDetector
    detector = yolov4ObjectDetector('tiny-yolov4-coco'); %#ok<UNRCH>
    furniture = detectFurniture(img, detector);
else
    furniture = struct('type', {}, 'centerPixel', {}, 'bbox', {}, 'score', {});
end

%% 6. Extract dimension/label text via OCR
dims = extractDimensionText(img);

%% 7. Save combined output (schema matches floorplan_output.json from Python)
output.walls = walls;
output.rooms = rooms;
output.furniture = furniture;
output.dimensions = dims;

jsonStr = jsonencode(output, 'PrettyPrint', true);
fid = fopen('floorplan_output.json', 'w');
fwrite(fid, jsonStr, 'char');
fclose(fid);

fprintf('Saved floorplan_output.json (%d walls, %d rooms, %d furniture, %d text tokens)\n', ...
    numel(walls), numel(rooms), numel(furniture), numel(dims));

%% 8. pixelToMeterScale -- convert floor-plan pixel units to meters
% Measure this from a wall of KNOWN real-world length. Example: if a
% wall you know is 3.5 m long measured 350 px in `walls`, the scale is
% 3.5/350 = 0.01 m/px. The synthetic test_floorplan.png was drawn at
% ~100 px/m, so 0.01 is the correct default for it -- replace this for
% your own printed/photographed floor plan.
pixelToMeterScale = 0.01; % <-- replace with your measured scale

%% 9. Save reference geometry for liveARDemo.m
save('referenceFloorplan.mat', 'walls', 'rooms', 'pixelToMeterScale');
fprintf('Saved referenceFloorplan.mat (used by liveARDemo.m)\n');

%% 10. Optional: single-frame AR preview if an AprilTag + calibration are available
if ~isempty(intrinsics)
    [camPose, tagId, ~] = estimatePoseFromTag(img, intrinsics, tagFamily, tagSizeM);
    if ~isempty(camPose)
        arFrame = renderARWalls(img, walls, rooms, intrinsics, camPose, ...
            pixelToMeterScale);
        figure('Name', sprintf('AR overlay (tag id=%d)', tagId));
        imshow(arFrame);
    else
        fprintf('No AprilTag detected in the static image -- skipping AR preview.\n');
    end
end
