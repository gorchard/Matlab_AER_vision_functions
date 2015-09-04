% vid = ShowTDEM(TD, EM, TPF, [Tstart, Tstop])
%
% This function displays EM grayscale with TD data superimposed, optional
% arguments TPF, [Tstart, Tstop]
% 
% vid - A video object returned by the function
%
% TS  - The Temporal Difference (TD) events to be shown
% 
% EM  - The Exposure Measurement (EM) events to be shown
%
% TPF - The Time Per Frame (TPF) indicates how much to advance time by per frame (default is 1/24 seconds)
%
% [Tstart,Tstop] - Optional start and stop time. [-1,-1] means start at the
% beginning and play to the end of the recording

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