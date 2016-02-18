% ShowTDcontour replays temporal difference events and optionally, a contour of the object, and returns a video object
% vid = ShowTDcontour(TD, Contour, TPF, FL, [Tstart,Tstop])
% all arguments except TD are optional
%
% contour - vertices of a contour outlining the object. These bounding
% boxes and shape outlines are available as part of the dataset download at http://www.garrickorchard.com/datasets/n-caltech101
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
% written by Garrick Orchard - July 2015

function vid = ShowTDcontour(varargin)
close all
s = warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
timeconst = 1e-6;
TD = varargin{1};

TD.p = TD.p - min(TD.p) + 1;

if nargin > 1
    contour = varargin{2};
else
    disp('No "contour" argument passed');
end

%FPS is 1/TPF
if nargin > 2
    if isempty(varargin{3})
        FPS = 24;
    else
        FPS = 1/varargin{3};
    end
else
    FPS = 24;
end

%FL is overlap
if nargin >3
    if isempty(varargin{4})
        Overlap = 1;
    else
        Overlap = varargin{4};
    end
else
    Overlap = 1;
end

if nargin > 4
    if isempty(varargin{5})
        Tmin = 1;
        Tmax = length(TD.ts);
    else
        if(varargin{5}(1) == -1)
            Tmin = 1;
        else
            Tmin = find(TD.ts>varargin{5}(1),1);
        end
        if(varargin{5}(2) == -1)
            Tmax = length(TD.ts);
        else
            Tmax = find(TD.ts>varargin{5}(2),1);
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
    hold on
    
    %% show contour
    currentTime = TD.ts(i);
    if nargin>1
        obj_contour = movingContour(contour, currentTime); % this function accounts for object motion relative to the sensor as a result of the saccades
        plot(obj_contour(1,:), obj_contour(2,:), 'm','linewidth',4);
    end

    %%
    title(TD.ts(i))
    axis off
    drawnow();
    
    t2 = t1 + FrameLength*Overlap;
    t1 = t1 + FrameLength;
    vid(k).cdata = Image;
    Image = ImageBack;
    k=k+1;
end