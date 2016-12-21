% vid = ShowEM(EM, TPF, time_span)
%   Displays Exposure Measurement (EM) data as a video
%
% TAKES IN:
%   'EM'
%       A struct of Exposure Measurement (EM) events in the format
%       EM.x =  pixel X locations, strictly positive integers only (TD.x>0)
%       EM.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%   	EM.p =  event polarity. EM.p = 0 for first threshold, EM.p = 1 for 
%               second threshold.
%       EM.ts = event timestamps in units of microseconds
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

function vid = ShowEM(varargin)
close all
timeconst = 1e-6;
EM = varargin{1};

if length(varargin) > 1
    FPS = 1/varargin{2};
else
    FPS = 24;
end

if nargin > 3
    if isempty(varargin{4})
        Tmin = 1;
        Tmax = length(EM.ts);
    else
        if(varargin{4}(1) == -1)
            Tmin = 1;
        else
            Tmin = find(EM.ts>varargin{4}(1),1);
        end
        if(varargin{4}(2) == -1)
            Tmax = length(EM.ts);
        else
            Tmax = find(EM.ts>varargin{4}(2),1);
        end
        if isempty(Tmax)
            Tmax = length(EM.ts);
        end
    end
else
    Tmin = 1;
    Tmax = length(EM.ts);
end

FrameLength = 1/(FPS*timeconst);

t1 = EM.ts(Tmin) + FrameLength;

Image = ones(max(EM.y),max(EM.x))*inf;
colormap gray
i = 1;
k = 1;
if Tmax == 0
    Tmax = length(EM.ts);
end

thresh0 = zeros(max(EM.y),max(EM.x));
thresh0Valid = zeros(max(EM.y),max(EM.x));
while (i<Tmax)
    while ((EM.ts(i) < t1) && (i<Tmax))
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
    
    a = sort(-log(Image(~isinf(Image))));
    if ~isempty(a)
        minVal = a(min(1e3, ceil(length(a)/2)))-0.1;
        maxVal = a(max(length(a)-1e3, ceil(length(a)/2)));
    else
        minVal = 0;
        maxVal = 0;
    end
    img = -log(Image);
    img(:,:,2) = -log(Image);
    img(:,:,3) = -log(Image);
    img(img<minVal) = minVal;
    img(img>maxVal) = maxVal;
    img = (img-minVal)./(maxVal-minVal);    
    
    imshow(img, 'InitialMagnification', 'fit')
    axis off
%     drawnow();
    
    t1 = t1 + FrameLength;
    vid(k).cdata = img;
    k = k+1;
end