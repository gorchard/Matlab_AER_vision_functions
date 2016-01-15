% vid = ShowTDEM(TD, EM, TPF, time_span)
%   displays Exposure Measurement (EM, grayscale) video with Temporal
%   Difference (TD, change detection) events superimposed.
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
%   'EM'
%       A struct of Exposure Measurement (EM) events in the format
%           EM.x =  pixel X locations, strictly positive integers only (TD.x>0)
%           EM.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%           EM.p =  event polarity. EM.p = 0 for first threshold, EM.p = 1 for 
%               second threshold.
%           EM.ts = event timestamps in units of microseconds
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
% written by Garrick Orchard - June 2014
% garrickorchard@gmail.com

function vid = ShowTDEM(varargin)
close all
timeconst = 1e-6;
TD = varargin{1};
EM = varargin{2};

if length(varargin) > 2
    FPS = 1/varargin{3};
else
    FPS = 24;
end
if length(varargin) > 3
    TminEM = find(EM.ts>varargin{4}(1), 1);
    TmaxEM = find(EM.ts>varargin{4}(2), 1);
    
    TminTD = find(TD.ts>varargin{4}(1), 1);
    TmaxTD = find(TD.ts>varargin{4}(2), 1);
else
    TminEM = 1;
    TmaxEM = length(EM.ts);
    
    TminTD = 1;
    TmaxTD = length(TD.ts);
end
if TminEM < 1
    TminEM = 1;
end
if TminTD < 1
    TminTD = 1;
end
if TmaxEM < 1
    TmaxEM = length(EM.ts);
end
if TmaxTD < 1
    TmaxTD = length(TD.ts);
end

FrameLength = 1/(FPS*timeconst);

t1 = EM.ts(TminEM) + FrameLength;

Image = ones(max(max(EM.y), max(TD.y)),max(max(EM.x), max(TD.x)))*inf;
colormap gray
i = 1;
j = 1;
k=1;

thresh0 = zeros(max(EM.y),max(EM.x));
thresh0Valid = zeros(max(EM.y),max(EM.x));

TD.p = TD.p - min(TD.p) + 1;
cc = hsv(length(unique(TD.p)));


while (i<TmaxEM)
    %% update background with APS data
    while ((EM.ts(i) < t1) && (i<TmaxEM))
        if (EM.p(i) == 0)
            thresh0Valid(EM.y(i), EM.x(i))  = 1;
            thresh0(EM.y(i), EM.x(i))       = EM.ts(i);
        else
            if thresh0Valid(EM.y(i), EM.x(i)) == 1
                thresh0Valid(EM.y(i), EM.x(i)) = 0;
                Image(EM.y(i), EM.x(i))  = EM.ts(i) - thresh0(EM.y(i), EM.x(i));
            end
        end
        i = i+1;
    end
    
    %% convert to grayscale image
    a = sort(-log(Image(~isinf(Image))));
    if ~isempty(a)
        minVal = a(min(1e3, floor(length(a)/2)))-0.1;
        maxVal = a(max(length(a)-1e3, ceil(length(a)/2)));
    else
        minVal = -10e3;
        maxVal = 0;
    end
    img = -log(Image);
    img(:,:,2) = -log(Image);
    img(:,:,3) = -log(Image);
    img(img<minVal) = minVal;
    img(img>maxVal) = maxVal;
    img = (img-minVal)./(maxVal-minVal);
    
    
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
    vid(k) = getframe;
    k = k+1;
end