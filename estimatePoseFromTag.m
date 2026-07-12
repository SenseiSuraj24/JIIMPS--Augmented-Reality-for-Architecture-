function [camPose, tagId, tagLoc] = estimatePoseFromTag(frame, intrinsics, tagFamily, tagSizeMeters)
%ESTIMATEPOSEFROMTAG Estimate the camera pose relative to a floor plan
%   using a printed AprilTag as the known reference feature.
%
%   [camPose, tagId, tagLoc] = ESTIMATEPOSEFROMTAG(frame, intrinsics, ...
%       tagFamily, tagSizeMeters)
%
%   Inputs:
%       frame          - RGB or grayscale video frame
%       intrinsics     - cameraIntrinsics object from the Camera
%                        Calibrator App (load from your calibration .mat)
%       tagFamily      - e.g. 'tag36h11' (print your tag at tagSizeMeters)
%       tagSizeMeters  - physical side length of the printed tag, in meters
%
%   Output:
%       camPose - rigidtform3d giving the CAMERA's pose in the TAG's
%                 (i.e. the floor plan's) world coordinate frame. Returns
%                 [] if no tag is found. This is the object you feed to
%                 world2img/renderARWalls to project 3D wall geometry
%                 defined in floor-plan coordinates back into the image.
%       tagId   - detected tag ID (empty if none found)
%       tagLoc  - 4x2 pixel coordinates of the tag corners (for debugging)
%
%   Note on convention: readAprilTag returns pose(s) as the
%   transformation FROM the tag frame TO the camera frame (i.e. it is
%   already the extrinsics you'd use directly). world2img, however,
%   expects the camera's pose IN the world frame, so we invert it here.

if size(frame, 3) == 3
    gray = rgb2gray(frame);
else
    gray = frame;
end

[ids, locs, poses] = readAprilTag(gray, tagFamily, intrinsics, tagSizeMeters);

if isempty(ids)
    camPose = [];
    tagId = [];
    tagLoc = [];
    return
end

% If multiple tags are visible, use the first detection.
tagId = ids(1);
tagLoc = locs(:, :, 1);
tagToCam = poses(1);          % transform: tag frame -> camera frame
camPose = invert(tagToCam);   % transform: camera pose in tag/world frame
end
