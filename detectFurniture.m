function furniture = detectFurniture(img, detector, varargin)
%DETECTFURNITURE Detect furniture/symbols on a floor plan using a
%   pretrained deep-learning object detector (MATLAB equivalent of the
%   YOLOv8 + ultralytics block in the Python reference script).
%
%   furniture = DETECTFURNITURE(img, detector) runs DETECTOR (any object
%   supporting MATLAB's detect(detector, img) interface, e.g. a
%   yolov4ObjectDetector) on img and returns a struct array with fields
%   type, centerPixel, bbox, score.
%
%   To build a detector (requires Deep Learning Toolbox + the
%   "Computer Vision Toolbox Model for YOLO v4 Object Detection"
%   support package):
%       detector = yolov4ObjectDetector('tiny-yolov4-coco');
%
%   Note: COCO classes (chair, couch, bed, tv, etc.) only cover generic
%   furniture categories. For real floor-plan symbols (doors, windows,
%   fixtures) you would fine-tune a detector on a labeled symbol dataset
%   using trainYOLOv4ObjectDetector -- see the "Advanced work" bullet
%   about markers for windows/doors/furniture.

p = inputParser;
addParameter(p, 'ConfidenceThreshold', 0.3);
parse(p, varargin{:});
conf = p.Results.ConfidenceThreshold;

furniture = struct('type', {}, 'centerPixel', {}, 'bbox', {}, 'score', {});

if isempty(detector)
    warning('detectFurniture: no detector supplied, skipping furniture detection.');
    return
end

[bboxes, scores, labels] = detect(detector, img, 'Threshold', conf);

for i = 1:size(bboxes, 1)
    bb = bboxes(i, :); % [x y w h]
    cx = bb(1) + bb(3) / 2;
    cy = bb(2) + bb(4) / 2;
    furniture(end + 1) = struct( ...  %#ok<AGROW>
        'type', char(labels(i)), ...
        'centerPixel', [cx, cy], ...
        'bbox', bb, ...
        'score', scores(i));
end

fprintf('detectFurniture: found %d objects\n', numel(furniture));
end
