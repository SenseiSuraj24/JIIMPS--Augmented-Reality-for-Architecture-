function rooms = detectRooms(img, varargin)
%DETECTROOMS Segment enclosed rooms in a floor plan using connected
%   components on the inverted edge/wall mask (MATLAB equivalent of the
%   cv2.connectedComponentsWithStats step in the Python reference script).
%
%   rooms = DETECTROOMS(img) returns a struct array with fields
%   id, centroidPixel, colorHex, areaPx.
%
%   rooms = DETECTROOMS(img,'MinArea',1500) sets the minimum blob area
%   (in pixels) to keep, filtering out noise.
%
%   rooms = DETECTROOMS(img,'MaxArea',Inf) sets the maximum blob area.
%   Setting this to, e.g., 0.5 * numel(img(:,:,1)) is a robust way to
%   exclude the image background, which is almost always the single
%   largest connected component.

p = inputParser;
addParameter(p, 'MinArea', 1500);
addParameter(p, 'MaxArea', Inf);   % filter background (largest component)
parse(p, varargin{:});
minArea = p.Results.MinArea;
maxArea = p.Results.MaxArea;

if size(img, 3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end

BW = edge(imgaussfilt(gray, 1), 'Canny');
wallMask = imdilate(BW, strel('disk', 2)); % close small gaps in wall lines
freeSpace = ~wallMask;                     % everything that is not a wall

CC = bwconncomp(freeSpace, 4);
stats = regionprops(CC, 'Area', 'Centroid');

% If MaxArea is Inf, automatically exclude the single largest component
% (which is almost always the image background).
if isinf(maxArea) && numel(stats) > 1
    allAreas = [stats.Area];
    maxArea  = max(allAreas) - 1;   % exclude the largest blob
end

palette = {'#FF6B6B', '#4D96FF', '#6BCB77', '#FFD93D', ...
           '#9B5DE5', '#F15BB5', '#00BBF9'};

% Preallocate output struct array for performance.
rooms = struct('id', {}, 'centroidPixel', {}, 'colorHex', {}, 'areaPx', {});
roomIdx = 0;
for i = 1:numel(stats)
    a = stats(i).Area;
    if a >= minArea && a <= maxArea
        roomIdx = roomIdx + 1;
        rooms(roomIdx) = struct( ...
            'id', sprintf('Room_%d', roomIdx - 1), ...
            'centroidPixel', stats(i).Centroid, ...
            'colorHex', palette{mod(roomIdx - 1, numel(palette)) + 1}, ...
            'areaPx', a);
    end
end

fprintf('detectRooms: found %d rooms\n', numel(rooms));
end
