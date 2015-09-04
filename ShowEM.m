% This function displays Exposure Measurement (EM) data, optional arguments TPF, [Tstart, Tstop]
% vid = ShowAPS(EM, TPF, [Tstart, Tstop])
%
% vid - A video object returned by the function
%
% EM  - The Exposure Measurement (EM) events to be shown
%
% TPF - The Time Per Frame (TPF) indicates how much to advance time by per frame (default is 1/24 seconds)
%
% [Tstart,Tstop] - Optional start and stop time. [-1,-1] means start at the
% beginning and play to the end of the recording

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
    minVal = a(min(1e3, floor(length(a)/2)))-0.1;
    maxVal = a(max(length(a)-1e3, ceil(length(a)/2)));
    
    imshow(-log(Image), [minVal,maxVal], 'InitialMagnification', 'fit')
    axis off
%     drawnow();
    
    t1 = t1 + FrameLength;
    vid(k) = getframe;
    k = k+1;
end