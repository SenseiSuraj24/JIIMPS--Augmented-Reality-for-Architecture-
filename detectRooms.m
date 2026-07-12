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

p = inputParser;
addParameter(p, 'MinArea', 1500);
parse(p, varargin{:});
minArea = p.Results.MinArea;

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

palette = {'#FF6B6B', '#4D96FF', '#6BCB77', '#FFD93D', ...
           '#9B5DE5', '#F15BB5', '#00BBF9'};

rooms = struct('id', {}, 'centroidPixel', {}, 'colorHex', {}, 'areaPx', {});
roomIdx = 0;
for i = 1:numel(stats)
    if stats(i).Area > minArea
        rooms(end + 1) = struct( ...   %#ok<AGROW>
            'id', sprintf('Room_%d', roomIdx), ...
            'centroidPixel', stats(i).Centroid, ...
            'colorHex', palette{mod(roomIdx, numel(palette)) + 1}, ...
            'areaPx', stats(i).Area);
        roomIdx = roomIdx + 1;
    end
end

fprintf('detectRooms: found %d rooms\n', numel(rooms));
end
