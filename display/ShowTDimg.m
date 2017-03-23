% vid = ShowTDEM(TD, img, TPF, time_span)
%   displays an image (img) with Temporal Difference (TD, change detection) events superimposed.
% 
% TAKES IN:
%   'TD'     
%       A struct of events with format
%           TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
%           TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%           TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
%                   events
%           TD.ts = event timestamps in units of microseconds
% 
%   'image'
%       An image as an array of size [x, y] where each value is in the
%       range [0,1]
% 
%   'TPF' 
%       The Time Per Frame (TPF) indicates how much to advance time by per
%       frame (This argument is optional and defaults to 1/24 seconds).
%
%   'time_span' = [Tstart,Tstop]
%       An optional argument to specify the timepoints in the recording at
%       which playback should begin and end. A value of '-1' for Tstart
%       indicates to start at the beginning. A value of '-1' for Tstop
%       indicates to continue until the end of the recording.
% 
% RETURNS:
%   'vid' 
%       A Matlab video of the recording. The video can be saved to file by
%       using the function 'SaveMovie'.
%
% 
% written by Garrick Orchard - Dec 2016
% garrickorchard@gmail.com

function vid = ShowTDimg(varargin)
close all
timeconst = 1e-6;
TD = varargin{1};
image = varargin{2};

if length(varargin) > 2
    FPS = 1/varargin{3};
else
    FPS = 24;
end
if length(varargin) > 3
    TminTD = find(TD.ts>varargin{4}(1), 1);
    TmaxTD = find(TD.ts>varargin{4}(2), 1);
else
    TminTD = 1;
    TmaxTD = length(TD.ts);
end
if TminTD < 1
    TminTD = 1;
end
if TmaxTD < 1
    TmaxTD = length(TD.ts);
end

FrameLength = 1/(FPS*timeconst);

t1 = TD.ts(TminTD) + FrameLength;

if size(image, 3) == 1
    Image = repmat(image, [1,1,3]);
else
    Image = image;
end
colormap gray
j = 1;
k=1;

TD.p = TD.p - min(TD.p) + 1;
cc = hsv(length(unique(TD.p)));

Tmax = TmaxTD;
while (j<Tmax)
    img = Image; 
    
    %% superimpose TD data
    while ((TD.ts(j) < t1) && (j<TmaxTD))
        img(TD.y(j), TD.x(j), :) = cc(TD.p(j),:);
        j = j+1;
    end
    
    %% display
    imshow(img, 'InitialMagnification', 'fit');
    axis off
    drawnow();
    t1 = t1 + FrameLength;
    vid(k).cdata = img;
    k = k+1;
end