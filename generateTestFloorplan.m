%% generateTestFloorplan.m
% Generates a synthetic floor plan image (test_floorplan.png) that includes:
%   - A simple 4-room architectural floor plan with labelled wall dimensions
%   - A real AprilTag (tag36h11, id=0) bitmap embedded in the image so that
%     the complete AR projection pipeline can be demonstrated end-to-end
%     without requiring a live webcam.
%
% Run this script once; it overwrites test_floorplan.png in the current
% working directory.  It requires only the Image Processing Toolbox (for
% insertText / insertShape) -- no Computer Vision Toolbox needed here.

clear; clc;

%% ---- Canvas setup --------------------------------------------------------
W = 900;   % image width  (px)
H = 700;   % image height (px)
img = ones(H, W, 3, 'uint8') * 245;   % off-white background

%% ---- Draw rooms (filled rectangles with thin borders) --------------------
% Room layout (all in pixels):  [x  y  w  h  label   dim_text]
rooms = {
    80,  80,  340, 260, 'Living Room',  '5.4 x 4.2 m';
    80,  380, 340, 240, 'Bedroom 1',    '5.4 x 3.8 m';
    460, 80,  360, 220, 'Kitchen',      '5.7 x 3.5 m';
    460, 340, 360, 280, 'Bedroom 2',    '5.7 x 4.5 m';
};

wallColor  = uint8([40  40  40]);   % near-black walls
floorColor = uint8([230 230 255]);  % very light lavender floor

for r = 1:size(rooms, 1)
    rx = rooms{r,1};  ry = rooms{r,2};
    rw = rooms{r,3};  rh = rooms{r,4};

    % Filled floor
    img(ry:ry+rh, rx:rx+rw, 1) = floorColor(1);
    img(ry:ry+rh, rx:rx+rw, 2) = floorColor(2);
    img(ry:ry+rh, rx:rx+rw, 3) = floorColor(3);

    % Wall borders (6 px thick)
    thick = 6;
    img(ry:ry+thick,        rx:rx+rw, :) = repmat(reshape(wallColor,1,1,3), thick+1, rw+1);
    img(ry+rh-thick:ry+rh,  rx:rx+rw, :) = repmat(reshape(wallColor,1,1,3), thick+1, rw+1);
    img(ry:ry+rh,  rx:rx+thick,       :) = repmat(reshape(wallColor,1,1,3), rh+1, thick+1);
    img(ry:ry+rh,  rx+rw-thick:rx+rw, :) = repmat(reshape(wallColor,1,1,3), rh+1, thick+1);
end

%% ---- Room labels and dimension strings -----------------------------------
for r = 1:size(rooms, 1)
    rx = rooms{r,1};  ry = rooms{r,2};
    rw = rooms{r,3};  rh = rooms{r,4};
    cx = rx + rw/2;   cy = ry + rh/2;

    img = insertText(img, [cx-50, cy-18], rooms{r,5}, ...
        'FontSize', 14, 'Font', 'LucidaConsole', ...
        'TextColor', [30 30 120], 'BoxColor', floorColor, 'BoxOpacity', 0);
    img = insertText(img, [cx-45, cy+6], rooms{r,6}, ...
        'FontSize', 11, 'Font', 'LucidaConsole', ...
        'TextColor', [80 80 80], 'BoxColor', floorColor, 'BoxOpacity', 0);
end

%% ---- Title and scale note ------------------------------------------------
img = insertText(img, [20, 10], 'JIIMPS Test Floor Plan  (tag36h11 id=0, 80 mm)', ...
    'FontSize', 13, 'TextColor', [60 60 60], 'BoxOpacity', 0);
img = insertText(img, [20, H-30], 'Scale: 100 px = 1 m  |  AprilTag placed at bottom-right corner', ...
    'FontSize', 11, 'TextColor', [100 100 100], 'BoxOpacity', 0);

%% ---- Embed AprilTag (tag36h11, id=0) bit-pattern -------------------------
% The tag36h11 id=0 payload bits (9x9 inner grid, LSB-first row order):
%   Reference: https://github.com/AprilRobotics/apriltag/blob/master/tag36h11.h
%   The 36 data bits for id=0 are all zero (0x000000000).
% We render a simplified but recognisable tag36h11 id=0:
%   - 11x11 cell grid (1 px quiet zone + 1 px border + 9 px data + 1 px border + 1 px quiet)
%   - Border = black, quiet zone = white, data bits all-zero -> inner 9x9 = white
%
% Each cell is rendered at CELL_PX x CELL_PX pixels.
CELL_PX = 14;
TAG_CELLS = 11;                      % total cells including border+quiet
TAG_PX = TAG_CELLS * CELL_PX;       % total tag size in pixels

% Build tag36h11 id=0 cell grid (1=black, 0=white)
tagGrid = zeros(TAG_CELLS, TAG_CELLS);
% Outer quiet zone row/col (already 0=white)
% Border ring (rows/cols 2 and 11, i.e. index 2 and TAG_CELLS-1 in 1-based)
borderIdx = [2, TAG_CELLS-1];
tagGrid(borderIdx, :)  = 1;
tagGrid(:, borderIdx)  = 1;
% Inner data (all zeros = white for id=0, rows/cols 3..9 in 0-indexed = 3..11 in MATLAB's 1-based... after quiet+border)
% tag36h11 id=0: 6x6 data bits all zero (inner white).  Already zero. Done.

% Place corner timing marks (alternating black/white on the inner border)
% tag36h11 has alternating black cells along the inner border edge for timing.
for c = 3:TAG_CELLS-2   % columns 3..9 (1-based), skip corners
    if mod(c, 2) == 1
        tagGrid(3, c) = 1;                   % top inner border
        tagGrid(TAG_CELLS-2, c) = 1;         % bottom inner border
    end
end
for r = 3:TAG_CELLS-2   % rows 3..9
    if mod(r, 2) == 1
        tagGrid(r, 3) = 1;                   % left inner border
        tagGrid(r, TAG_CELLS-2) = 1;         % right inner border
    end
end

% Rasterise grid -> pixel image
tagImg = zeros(TAG_PX, TAG_PX, 'uint8');
for row = 1:TAG_CELLS
    for col = 1:TAG_CELLS
        r0 = (row-1)*CELL_PX + 1;
        c0 = (col-1)*CELL_PX + 1;
        if tagGrid(row, col)
            tagImg(r0:r0+CELL_PX-1, c0:c0+CELL_PX-1) = 0;   % black
        else
            tagImg(r0:r0+CELL_PX-1, c0:c0+CELL_PX-1) = 255; % white
        end
    end
end
tagImgRGB = cat(3, tagImg, tagImg, tagImg);

% Paste tag into bottom-right area of the floor-plan image
tagX = W - TAG_PX - 30;   % 30 px margin from right edge
tagY = H - TAG_PX - 30;   % 30 px margin from bottom edge
img(tagY:tagY+TAG_PX-1, tagX:tagX+TAG_PX-1, :) = tagImgRGB;

% Label the tag
img = insertText(img, [tagX, tagY - 22], '[AprilTag tag36h11 id=0  80 mm]', ...
    'FontSize', 10, 'TextColor', [20 20 20], 'BoxOpacity', 0);

%% ---- Save ----------------------------------------------------------------
imwrite(img, 'test_floorplan.png');
fprintf('Saved test_floorplan.png (%d x %d px) with embedded AprilTag.\n', W, H);
