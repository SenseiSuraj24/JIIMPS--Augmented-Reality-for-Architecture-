function walls = detectWalls(img, varargin)
%DETECTWALLS Detect wall line segments in a 2D floor plan image.
%   walls = DETECTWALLS(img) returns a struct array with fields
%   start, stop, length, angle describing each detected wall segment,
%   using edge detection + the Hough transform (MATLAB equivalent of the
%   cv2.Canny + cv2.HoughLinesP step in the Python reference script).
%
%   walls = DETECTWALLS(img,'Name',Value,...) allows tuning:
%       'CannyThreshold'   - [low high] for edge(), default auto
%       'MinLineLength'    - minimum segment length in px, default 40
%       'FillGap'          - max gap to merge collinear segments, default 10
%       'NumPeaks'         - number of Hough peaks to search, default 60
%       'Theta'            - Hough theta resolution, default -90:0.5:89.5
%
%   Example:
%       I = imread('floorplan.png');
%       walls = detectWalls(I);
%       imshow(I); hold on
%       for k = 1:numel(walls)
%           plot([walls(k).start(1) walls(k).stop(1)], ...
%                [walls(k).start(2) walls(k).stop(2)], 'g-', 'LineWidth', 2);
%       end

p = inputParser;
addParameter(p, 'CannyThreshold', []);
addParameter(p, 'MinLineLength', 40);
addParameter(p, 'FillGap', 10);
addParameter(p, 'NumPeaks', 60);
addParameter(p, 'Theta', -90:0.5:89.5);
parse(p, varargin{:});
opt = p.Results;

if size(img, 3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end

gray = imgaussfilt(gray, 1);

if isempty(opt.CannyThreshold)
    BW = edge(gray, 'Canny');
else
    BW = edge(gray, 'Canny', opt.CannyThreshold);
end

[H, T, R] = hough(BW, 'Theta', opt.Theta);
P = houghpeaks(H, opt.NumPeaks, 'Threshold', ceil(0.3 * max(H(:))));
lines = houghlines(BW, T, R, P, 'FillGap', opt.FillGap, ...
    'MinLength', opt.MinLineLength);

% Preallocate output struct array for performance.
nLines = numel(lines);
emptyCell = repmat({[]}, 1, nLines);
walls = struct( ...
    'start',        emptyCell, ...
    'stop',         emptyCell, ...
    'length',       emptyCell, ...
    'angle',        emptyCell, ...
    'height_mm',    emptyCell, ...
    'thickness_mm', emptyCell);

for k = 1:nLines
    xy = [lines(k).point1; lines(k).point2];
    len = norm(xy(1, :) - xy(2, :));
    ang = atan2d(xy(2, 2) - xy(1, 2), xy(2, 1) - xy(1, 1));
    walls(k) = struct( ...
        'start',        xy(1, :), ...
        'stop',         xy(2, :), ...
        'length',       len, ...
        'angle',        ang, ...
        'height_mm',    2500, ...   % default wall height, override per project
        'thickness_mm', 150);       % default wall thickness
end

fprintf('detectWalls: found %d wall segments\n', numel(walls));
end
