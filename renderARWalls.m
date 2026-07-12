function outFrame = renderARWalls(frame, walls, rooms, intrinsics, camPose, pixelToMeterScale, varargin)
%RENDERARWALLS Augment a video frame with a 3D representation of the
%   floor plan (extruded walls + tinted room floors), perspective-correct
%   for the current camera pose.
%
%   outFrame = RENDERARWALLS(frame, walls, rooms, intrinsics, camPose, ...
%       pixelToMeterScale) draws the walls/rooms (as returned by
%       detectWalls/detectRooms, in floor-plan PIXEL coordinates) onto
%       frame, after converting pixel coordinates to real-world meters
%       using pixelToMeterScale (meters per floor-plan pixel), and
%       projecting through the camera pose/intrinsics.
%
%   Optional name-value:
%       'WallAlpha'  - fill transparency for wall faces, default 0.55
%       'RoomAlpha'  - fill transparency for room floor tint, default 0.35
%
%   This is the MATLAB equivalent of the three.js BoxGeometry/
%   CylinderGeometry overlay logic in the Python/HTML reference, but
%   composited directly onto the live camera frame instead of a separate
%   3D scene.

p = inputParser;
addParameter(p, 'WallAlpha', 0.55);
addParameter(p, 'RoomAlpha', 0.35);
parse(p, varargin{:});
opt = p.Results;

outFrame = frame;

if isempty(camPose)
    return % no pose this frame -> nothing to draw
end

% ---- Room floor tint (drawn first, so walls sit on top) ----
for r = 1:numel(rooms)
    radiusPx = sqrt(rooms(r).areaPx / pi);
    theta = linspace(0, 2 * pi, 24);
    cx = rooms(r).centroidPixel(1);
    cy = rooms(r).centroidPixel(2);
    circPx = [cx + radiusPx * cos(theta); cy + radiusPx * sin(theta)];

    worldPts = [circPx(1, :)' * pixelToMeterScale, ...
                circPx(2, :)' * pixelToMeterScale, ...
                zeros(numel(theta), 1)]; % floor plane z = 0

    imgPts = world2img(worldPts, camPose, intrinsics);
    if any(~isfinite(imgPts(:)))
        continue
    end
    col = hex2rgbUint8(rooms(r).colorHex);
    outFrame = insertShape(outFrame, 'FilledPolygon', imgPts(:)', ...
        'Color', col, 'Opacity', opt.RoomAlpha);
end

% ---- Extruded walls ----
for w = 1:numel(walls)
    hZ = walls(w).height_mm / 1000; % meters
    x1 = walls(w).start(1) * pixelToMeterScale;
    y1 = walls(w).start(2) * pixelToMeterScale;
    x2 = walls(w).stop(1) * pixelToMeterScale;
    y2 = walls(w).stop(2) * pixelToMeterScale;

    % 4 top-face corners of the wall slab at floor plane (z=0) and
    % ceiling plane (z=hZ); we only need the 4 verticals + 2 caps
    % rendered as a wireframe/translucent quad for clarity+speed.
    baseWorld = [x1 y1 0; x2 y2 0; x2 y2 hZ; x1 y1 hZ];
    imgPts = world2img(baseWorld, camPose, intrinsics);
    if any(~isfinite(imgPts(:)))
        continue
    end
    outFrame = insertShape(outFrame, 'FilledPolygon', imgPts(:)', ...
        'Color', [230 230 230], 'Opacity', opt.WallAlpha);
    outFrame = insertShape(outFrame, 'Polygon', imgPts(:)', ...
        'Color', [40 40 40], 'LineWidth', 2);
end
end

function rgb = hex2rgbUint8(hexStr)
hexStr = erase(hexStr, '#');
rgb = uint8([hex2dec(hexStr(1:2)), hex2dec(hexStr(3:4)), hex2dec(hexStr(5:6))]);
end
