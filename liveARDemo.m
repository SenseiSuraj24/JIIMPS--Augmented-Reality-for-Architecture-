%% liveARDemo.m
% Real-time AR demo: run the floor-plan feature detection ONCE on a
% reference photo/scan of the plan, then continuously track an AprilTag
% placed on the paper to recover the live camera pose each frame and
% project the 3D wall/room geometry back onto the webcam feed.
%
% Prerequisites:
%   1. Calibrate your webcam with the Camera Calibrator App and export
%      cameraParams.mat (variable name: cameraParams).
%   2. Print an AprilTag (family 'tag36h11' by default) at a known size
%      and tape it to a fixed, known position on the floor-plan sheet.
%   3. Run floorplan_AR_main.m once on a flat photo of the plan to get
%      `walls`, `rooms`, and to measure pixelToMeterScale (see notes
%      below). Save those to referenceFloorplan.mat.

clear; clc; close all;

%% Configuration
calibFile   = "cameraParams.mat";
refFile     = "referenceFloorplan.mat"; % contains walls, rooms, pixelToMeterScale
tagFamily   = "tag36h11";
tagSizeM    = 0.08;

%% Load calibration
S = load(calibFile);
intrinsics = S.cameraParams.Intrinsics;

%% Load reference floor-plan geometry (from floorplan_AR_main.m)
R = load(refFile, 'walls', 'rooms', 'pixelToMeterScale');
walls = R.walls;
rooms = R.rooms;
pixelToMeterScale = R.pixelToMeterScale;

%% Open webcam
cam = webcam; % pick a specific camera with webcam('Name') if needed
cam.Resolution = cam.AvailableResolutions{1};

fig = figure('Name', 'Live AR Floor Plan (press Q to quit)');
imgHandle = [];

fprintf('Starting live AR loop. Close the figure window to stop.\n');

while ishandle(fig)
    frame = snapshot(cam);

    [camPose, tagId, ~] = estimatePoseFromTag(frame, intrinsics, tagFamily, tagSizeM);

    if ~isempty(camPose)
        outFrame = renderARWalls(frame, walls, rooms, intrinsics, camPose, ...
            pixelToMeterScale);
        outFrame = insertText(outFrame, [10 10], ...
            sprintf('Tag %d locked - AR active', tagId), ...
            'BoxColor', 'green', 'TextColor', 'black');
    else
        outFrame = insertText(frame, [10 10], ...
            'No AprilTag detected', 'BoxColor', 'red', 'TextColor', 'white');
    end

    if isempty(imgHandle) || ~ishandle(imgHandle)
        imgHandle = imshow(outFrame);
    else
        set(imgHandle, 'CData', outFrame);
    end
    drawnow limitrate

    if ~ishandle(fig)
        break
    end
end

clear cam
fprintf('Live AR loop stopped.\n');
