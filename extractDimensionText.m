function dims = extractDimensionText(img)
%EXTRACTDIMENSIONTEXT Extract text/dimension labels from a floor plan
%   using MATLAB's built-in OCR (Computer Vision Toolbox), equivalent to
%   the EasyOCR block in the Python reference script.
%
%   dims = EXTRACTDIMENSIONTEXT(img) returns a struct array with fields
%   text, confidence, boundingBox.

if size(img, 3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end

results = ocr(gray);

dims = struct('text', {}, 'confidence', {}, 'boundingBox', {});
for i = 1:numel(results.Words)
    if isnan(results.WordConfidences(i))
        continue
    end
    dims(end + 1) = struct( ...  %#ok<AGROW>
        'text', results.Words{i}, ...
        'confidence', round(results.WordConfidences(i), 2), ...
        'boundingBox', results.WordBoundingBoxes(i, :));
end

fprintf('extractDimensionText: found %d text tokens\n', numel(dims));
end
