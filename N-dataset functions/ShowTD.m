% ShowTD replays temporal difference events and returns a video object
% vid = ShowTD(TD, TPF, FL, [Tstart,Tstop], Scale)
% all arguments except TD are optional
%
% vid - A video object returned by the function
%
% TD  - The Temporal Difference (TD) events to be shown
%
% TPF - The Time Per Frame (TPF) indicates how much to advance time by per frame (default is 1/24 seconds)
%
% FL  - The Frame Length (FL) is the amount of data (measured in time) to show in each frame as a
% percentage of TPF. Default is 1
%
% [Tstart,Tstop] - Optional start and stop time
% 
% Written by Garrick Orchard - July 2015

function vid = ShowTD(varargin)
close all
s = warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
timeconst = 1e-6;
TD = varargin{1};

TD.p = TD.p - min(TD.p) + 1;

%FPS is 1/TPF
if nargin > 1
    if isempty(varargin{2})
        FPS = 24;
    else
        FPS = 1/varargin{2};
    end
else
    FPS = 24;
end

%FL is overlap
if nargin >2
    if isempty(varargin{3})
        Overlap = 1;
    else
        Overlap = varargin{3};
    end
else
    Overlap = 1;
end

if nargin > 3
    if isempty(varargin{4})
        Tmin = 1;
        Tmax = length(TD.ts);
    else
        if(varargin{4}(1) == -1)
            Tmin = 1;
        else
            Tmin = find(TD.ts>varargin{4}(1),1);
        end
        if(varargin{4}(2) == -1)
            Tmax = length(TD.ts);
        else
            Tmax = find(TD.ts>varargin{4}(2),1);
        end
        if isempty(Tmax)
            Tmax = length(TD.ts);
        end
    end
else
    Tmin = 1;
    Tmax = length(TD.ts);
end

FrameLength = 1/(FPS*timeconst);
t1 = TD.ts(Tmin) + FrameLength;
t2 = TD.ts(Tmin) + FrameLength*Overlap;

ImageBack = zeros(max(TD.y),max(TD.x),3);

axis image
i = Tmin;
cc = hsv(max(TD.p));
Image = ImageBack;
k=1;
nFrames = ceil((TD.ts(Tmax)-TD.ts(Tmin))/FrameLength);
vid(1:nFrames) = struct('cdata', ImageBack, 'colormap', []);
while (i<Tmax)
    j=i;
    while ((TD.ts(j) < t2) && (j<Tmax))
        Image(TD.y(j), TD.x(j), :) = cc(TD.p(j),:);
        j = j+1;
    end
    while ((TD.ts(i) < t1) && (i<Tmax))
        i = i+1;
    end
    imshow(Image, 'InitialMagnification', 'fit');
    title(TD.ts(i))
    axis off
    drawnow();
    
    t2 = t1 + FrameLength*Overlap;
    t1 = t1 + FrameLength;
    vid(k).cdata = Image;
    Image = ImageBack;
    k=k+1;
end