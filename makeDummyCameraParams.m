%% makeDummyCameraParams.m
% Generates a PLACEHOLDER cameraParams.mat so you can test-run
% floorplan_AR_main.m / liveARDemo.m end-to-end before doing a real
% calibration. The intrinsics here are rough, typical-webcam estimates
% (not measured from your actual camera), so:
%
%   - Wall/room detection, OCR, and JSON export are unaffected (they
%     don't use intrinsics) and will be fully accurate.
%   - AR pose/projection (world2img) will RUN without erroring, but the
%     3D overlay will NOT be metrically accurate -- walls may appear
%     slightly mis-scaled or skewed. Good enough to confirm the code
%     path works; not good enough for a final demo/submission.
%
% Replace this with a real calibration ASAP:
%   1. Print a checkerboard (e.g. the one at
%      https://github.com/opencv/opencv/blob/4.x/doc/pattern.png,
%      or generate one from MATLAB's own calibration pattern generator
%      via the Camera Calibrator App itself).
%   2. Take 15-20 photos of it at different angles/distances with the
%      SAME camera/resolution you'll use for the live demo.
%   3. Open the app:  cameraCalibrator
%      Add your images, set the checkerboard square size in mm, run
%      Calibrate, then Export Camera Parameters -> save the exported
%      variable as cameraParams.mat (variable name must be
%      "cameraParams" for the other scripts to load it directly, or
%      adjust the load lines in floorplan_AR_main.m / liveARDemo.m).

clear; clc;

% --- Adjust to match the resolution you'll actually capture at ---
imageWidth  = 1280;
imageHeight = 720;

% Rough focal length guess for a typical laptop/USB webcam (~60-70 deg
% horizontal FOV). This is the main source of inaccuracy -- real
% calibration typically finds focal lengths noticeably different from
% this guess, especially for phone cameras or wide-angle webcams.
fx = imageWidth;   % ~1 pixel/degree-ish rule of thumb for ~60-70 deg FOV
fy = imageWidth;
cx = imageWidth / 2;
cy = imageHeight / 2;

intrinsicMatrix = [fx 0 0; 0 fy 0; cx cy 1]; % MATLAB uses the transposed form

intrinsics = cameraIntrinsics([fx fy], [cx cy], [imageHeight imageWidth]);

% Wrap in a cameraParameters object so downstream code that expects
% cameraParams.Intrinsics works unchanged.
cameraParams = cameraParameters('IntrinsicMatrix', intrinsicMatrix, ...
    'ImageSize', [imageHeight imageWidth]);

save('cameraParams.mat', 'cameraParams');
fprintf(['Saved PLACEHOLDER cameraParams.mat (%dx%d, fx=fy=%.0f).\n' ...
    'Replace with a real Camera Calibrator App export before your final run.\n'], ...
    imageWidth, imageHeight, fx);
