function [ROIevts] = ExtractROI(varargin)
% ROI_TD = ExtractROI(TD, [x,y], [x_size, y_size], [t_min, t_max])
%   Extracts a spatio-temporal Region Of Interest (ROI) from the events TD
% 
% TAKES IN:  
% 'TD' 
%       The events from which the ROI is to be extracted. TD is a struct
%       with format:
%           TD.x =  pixel X locations
%           TD.y =  pixel Y locations
%           TD.p =  event polarity (not used by this function)
%           TD.ts = event timestamps, typically in microseconds 
% 
% '[x,y]'   
%       The top left corner of the spatial ROI in pixels. Leave empty
%       if only a temporal ROI is required.
% 
% '[x_size, y_size]'
%        The spatial size of the ROI in pixels. Leave empty if only a
%        temporal ROI is required.
% 
% '[t_min, t_max]' 
%       The start and end times of the temporal region of interest in the
%       same units as the timestamps of the events (typically microseconds)
% 
% 
% RETURNS:
% 'ROIevts'
%       A struct of the same format as 'TD', but only containing events
%       which occur within the stated ROI
% 
% 
% written by Garrick Orchard - June 2014
% garrickorchard@gmail.com

ROIevts = varargin{1};
invalidIndices = zeros(size(ROIevts.x));

if nargin > 1 %if multiple arguments were passed
    if ~isempty(varargin{2}) && ~isempty(varargin{3}) %and if an roi location and size were set
        loc = varargin{2};
        ROIsize = varargin{3};
        
        %mark these events as invalid
        invalidIndices = invalidIndices | (ROIevts.x < loc(1)) | (ROIevts.x > loc(1)+ ROIsize(1)) | (ROIevts.y < loc(2)) | (ROIevts.y > loc(2) + ROIsize(2)); 
        
        ROIevts.x = ROIevts.x-loc(1) + 1; %shift to the ROI origin
        ROIevts.y = ROIevts.y-loc(2) + 1;
    end
end

if nargin > 3
    ROItime = varargin{4};
    if ROItime(1) == -1
        ROItime(1) = -inf;
    end
    if ROItime(2) == -1
        ROItime(2) = inf;
    end
    
    invalidIndices = invalidIndices | (ROIevts.ts<ROItime(1)) | (ROIevts.ts>ROItime(2));
end

ROIevts = RemoveNulls(ROIevts, invalidIndices);
