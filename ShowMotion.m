function vid = ShowMotion(varargin)
% vid = ShowMotion(OF, TPF, FL, time_span, Scale)
%   Shows a video of Optical Flow (OF) events and returns a video
%   object which can be saved to AVI using the 'SaveMovie' function.  
%   All arguments except OF are optional.
%
% TAKES IN:
%   'OF'
%       A struct of Optical Flow (OF) events with format:
%           OF.x =  pixel X locations
%           OF.y =  pixel Y locations
%           OF.vx =  x-direction velocities in pixels per second
%           OF.vy =  y-direction velocities in pixels per second
%           OF.p =  event polarity
%           OF.ts = event timestamps in microseconds
% 
%   'TPF'
%       Time Per Frame (TPF) is an optional argument specifying the
%       time-spacing between the start of subsequent frames (basically the
%       frame rate for the video). Defaults to 24FPS, which is a Time Per
%       Frame (TPF) of 1/24 seconds. 
% 
%   'FL'
%       Frame Length (FL) is an optional arguments specifying the time-span
%       of data to show per frame. Defaults to 1/24 seconds. If FL<TPF,
%       then not all data in a sequence will be shown. If FL>TPF then some
%       data will be repeated in subsequent frames.
% 
%   'time_span' = [Tstart,Tstop]
%       An optional argument specifying at which point in time the playback
%       should start (Tstart) and stop (Tstop). If time_span is not
%       specified, the entire recording will be shown by default.
% 
% 
% RETURNS:
%    'vid' 
%       A video object which can be saved to AVI using the 'SaveMovie'
%       function.
%
% 
% written by Garrick Orchard - December 2015
% garrickorchard@gmail.com

clf
s = warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
timeconst = 1e-6;
OF = varargin{1};

if ~isfield(OF, 'p')
    OF.p = zeros(size(OF.ts));
end
OF.p = round(OF.p - min(OF.p) + 1);

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
        Tmax = length(OF.ts);
    else
        if(varargin{4}(1) == -1)
            Tmin = 1;
        else
            Tmin = find(OF.ts>varargin{4}(1),1);
        end
        if(varargin{4}(2) == -1)
            Tmax = length(OF.ts);
        else
            Tmax = find(OF.ts>varargin{4}(2),1);
        end
        if isempty(Tmax)
            Tmax = length(OF.ts);
        end
    end
else
    Tmin = 1;
    Tmax = length(OF.ts);
end

FrameLength = 1/(FPS*timeconst);
t1 = OF.ts(Tmin) + FrameLength;
t2 = OF.ts(Tmin) + FrameLength*Overlap;

ImageBack = zeros(max(OF.y),max(OF.x),3);
vx = zeros(max(OF.y),max(OF.x));
vy = zeros(max(OF.y),max(OF.x));
[Y,X] = meshgrid(1:max(OF.x),1:max(OF.y));

scale = 5; %default scale to 5

axis image
i = Tmin;
cc = hsv(max(OF.p));
Image = ImageBack;
k=1;
nFrames = ceil((OF.ts(Tmax)-OF.ts(Tmin))/FrameLength);
vid(1:nFrames) = struct('cdata', ImageBack, 'colormap', []);
while (i<Tmax)
    j=i;
    while ((OF.ts(j) < t2) && (j<Tmax))
        Image(OF.y(j), OF.x(j), :) = cc(OF.p(j),:);
        vx(OF.y(j), OF.x(j), :) = OF.vx(j);
        vy(OF.y(j), OF.x(j), :) = OF.vy(j);
        j = j+1;
    end
    while ((OF.ts(i) < t1) && (i<Tmax))
        i = i+1;
    end
    imshow(Image, 'InitialMagnification', 'fit');
    hold on
    quiver(Y, X, vx, vy, scale, 'y', 'Autoscale','off'); 
    title(OF.ts(i))
    axis off
    drawnow();
    hold off
    
    t2 = t1 + FrameLength*Overlap;
    t1 = t1 + FrameLength;
    vid(k).cdata = Image;
    Image = ImageBack;
    vx = zeros(max(OF.y),max(OF.x));
    vy = zeros(max(OF.y),max(OF.x));
    k=k+1;
end