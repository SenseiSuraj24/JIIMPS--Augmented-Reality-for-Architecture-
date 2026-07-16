function dims = extractDimensionText(img, varargin)
%EXTRACTDIMENSIONTEXT Extract text/dimension labels from a floor plan
%   using MATLAB's built-in OCR (Computer Vision Toolbox), equivalent to
%   the EasyOCR block in the Python reference script.
%
%   dims = EXTRACTDIMENSIONTEXT(img) returns a struct array with fields
%   text, confidence, boundingBox.
%
%   dims = EXTRACTDIMENSIONTEXT(img,'MinLength',2) filters out tokens
%   whose text (after stripping whitespace) is shorter than MinLength
%   characters. This removes blank/whitespace OCR noise tokens.
%
%   dims = EXTRACTDIMENSIONTEXT(img,'MinConfidence',0.0) additionally
%   filters by word confidence score (0–1).

p = inputParser;
addParameter(p, 'MinLength',     2);    % exclude tokens with < 2 real chars
addParameter(p, 'MinConfidence', 0.0);  % exclude low-confidence detections
parse(p, varargin{:});
minLen  = p.Results.MinLength;
minConf = p.Results.MinConfidence;

if size(img, 3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end

results = ocr(gray);

% Preallocate output struct array for performance.
dims = struct('text', {}, 'confidence', {}, 'boundingBox', {});
count = 0;
for i = 1:numel(results.Words)
    conf = results.WordConfidences(i);

    % Skip NaN confidences (blank / whitespace-only OCR tokens).
    if isnan(conf)
        continue
    end

    % Skip tokens below the confidence threshold.
    if conf < minConf
        continue
    end

    % Skip tokens whose visible text is too short (OCR noise).
    tok = strtrim(results.Words{i});
    if numel(tok) < minLen
        continue
    end

    count = count + 1;
    dims(count) = struct( ...
        'text',        tok, ...
        'confidence',  round(conf, 2), ...
        'boundingBox', results.WordBoundingBoxes(i, :));
end

fprintf('extractDimensionText: found %d text tokens\n', numel(dims));
end
