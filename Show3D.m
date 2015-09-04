% Show3D(TD)
% Shows events in a 3D space-time plot
% TD is the event stream to plot
% the value of the TD.p field will determine the color of the event in the plot
function Show3D(varargin)
TD = varargin{1};
q = unique(TD.p);
cc = hsv(length(q));

for i=1:length(q)
    plot3(TD.x(TD.p == q(i)), TD.y(TD.p == q(i)), TD.ts(TD.p == q(i))./1e3, 'o', 'color', cc(i,:))
    hold on
end

if length(varargin) > 1
    Tracker = varargin{2};
    cc=hsv(length(Tracker));
    for i = 1:length(Tracker)
        plot3(Tracker{i}.X, Tracker{i}.Y, Tracker{i}.T/1e3, 'o', 'color', cc(i,:))
    end
end
grid on
