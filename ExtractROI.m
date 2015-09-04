% ROI_TD = ExtractROI(TD, [x,y], [xsize, ysize], [tmin, tmax])
% extracts a spatial Region Of Interest (ROI) defined by [x,y], [xsize, ysize]
% and a temporal region of interest defined by [tmin, tmax] where
% [x,y] is the location of the top left corner of the ROI, and
% [xsize, ysize] is the size of the region
% [tmin, tmax] are the start and end times of the temporal region
function [ROIevts] = ExtractROI(varargin)
ROIevts = varargin{1};
invalidIndices = zeros(size(ROIevts.x));

if nargin > 1 %if multiple arguments were passed
    if ~isempty(varargin{2}) && ~isempty(varargin{3}) %and if an roi location and size were set
        loc = varargin{2};
        ROIsize = varargin{3};
        
        ROIevts.x = ROIevts.x-loc(1) + 1; %shift to the ROI origin
        ROIevts.y = ROIevts.y-loc(2) + 1;
        
        %mark these events as invalid
        invalidIndices = invalidIndices | (ROIevts.x <= 0) | (ROIevts.x > ROIsize(1)) | (ROIevts.y <= 0) | (ROIevts.y > ROIsize(2)); 
    end
end

if nargin > 3
    ROItime = varargin{4};
    invalidIndices = invalidIndices | (ROIevts.ts<ROItime(1)) | (ROIevts.ts>ROItime(2));
end

ROIevts = RemoveNulls(ROIevts, invalidIndices);
