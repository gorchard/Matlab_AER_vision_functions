function [Tracker, C] = TrackTD(varargin)
% function [Tracker, C] = TrackTD(TD, distance, mixing_factor, time_difference)
% implements tracking on the struct 'TD'. 
% 
% Events further than 'distance' from a tracker will not be assigned to that tracker. 
% 
% When an event is assigned to a tracker, the tracker is updated with:
%       tracker.x = tracker.x*mixing_factor + event.x*(1-mixing_factor);
%       tracker.y = tracker.y*mixing_factor + event.y*(1-mixing_factor);
% 
% If a tracker does not receive any events for a time of 'time_difference'
% then the tracker is considered inactive
%
% Example: 
% [Tracker, C] = TrackTD(TD, 100, 0.95, 100e3)
%
TD = varargin{1};
DistSquared = varargin{2}.^2;
StayingPower = varargin{3};
TimeDiff = varargin{4};
ActiveTrackers = [];
numTrackers         = 0;
numActiveTrackers   = 0;
C = zeros(1, length(TD.ts));
i = 0;
d = 0;
while i <length(TD.ts)-100      %loop through all events
    for q = 1:100
        i = i+1;
        for j = 1:numActiveTrackers             %calculate the distance of current event to each tracker
            d(j) = (TD.x(i) - Tracker{ActiveTrackers(j)}.x(TrackerIndex(ActiveTrackers(j)))).^2 + (TD.y(i) - Tracker{ActiveTrackers(j)}.y(TrackerIndex(ActiveTrackers(j)))).^2;
        end
        
        [m,loc] = min(d(1:numActiveTrackers)); %find which tracker is closest
        
        if m < DistSquared  %if the closest tracker is within a predescribed distance, update that tracker
            Tracker{ActiveTrackers(loc)}.x(TrackerIndex(ActiveTrackers(loc))+1) = Tracker{ActiveTrackers(loc)}.x(TrackerIndex(ActiveTrackers(loc)))*StayingPower + TD.x(i)*(1-StayingPower);
            Tracker{ActiveTrackers(loc)}.y(TrackerIndex(ActiveTrackers(loc))+1) = Tracker{ActiveTrackers(loc)}.y(TrackerIndex(ActiveTrackers(loc)))*StayingPower + TD.y(i)*(1-StayingPower);
            Tracker{ActiveTrackers(loc)}.ts(TrackerIndex(ActiveTrackers(loc))+1) = TD.ts(i);
            Tracker{ActiveTrackers(loc)}.p(TrackerIndex(ActiveTrackers(loc))+1) = i;
            TrackerIndex(ActiveTrackers(loc)) = TrackerIndex(ActiveTrackers(loc))+1;
            C(i) = ActiveTrackers(loc);
        else %new tracker
            numTrackers = numTrackers+1;
            numActiveTrackers = numActiveTrackers+1;
            ActiveTrackers = [ActiveTrackers, numTrackers];
            TrackerIndex(numTrackers) = 1;
            Tracker{numTrackers}.x = zeros(1,30000);
            Tracker{numTrackers}.y = zeros(1,30000);
            Tracker{numTrackers}.ts = zeros(1,30000);
            Tracker{numTrackers}.p = zeros(1,30000);
            Tracker{numTrackers}.x(1) = TD.x(i);
            Tracker{numTrackers}.y(1) = TD.y(i);
            Tracker{numTrackers}.ts(1) = TD.ts(i);
            Tracker{numTrackers}.p(1) = i;
            C(i) = numTrackers;
        end
        
    end
    %housekeeping
    j = 1;
    while j < numActiveTrackers             %calculate the distance of current event to each tracker
        if TD.ts(i) - Tracker{ActiveTrackers(j)}.ts(TrackerIndex(ActiveTrackers(j)))  > TimeDiff
            Tracker{ActiveTrackers(j)}.x(TrackerIndex(ActiveTrackers(j))+1:end) = [];
            Tracker{ActiveTrackers(j)}.y(TrackerIndex(ActiveTrackers(j))+1:end) = [];
            Tracker{ActiveTrackers(j)}.ts(TrackerIndex(ActiveTrackers(j))+1:end) = [];
            Tracker{ActiveTrackers(j)}.p(TrackerIndex(ActiveTrackers(j))+1:end) = [];
            numActiveTrackers = numActiveTrackers-1;
            ActiveTrackers(j) = [];
        else
            j = j+1;
        end
    end
    
end

while i <length(TD.ts)        %loop through all events
    i = i+1;
    for j = 1:numActiveTrackers             %calculate the distance of current event to each tracker
        d(j) = (TD.x(i) - Tracker{ActiveTrackers(j)}.x(TrackerIndex(ActiveTrackers(j)))).^2 + (TD.y(i) - Tracker{ActiveTrackers(j)}.y(TrackerIndex(ActiveTrackers(j)))).^2;
    end
    
    [m,loc] = min(d(1:numActiveTrackers)); %find which tracker is closest
    
    if m < DistSquared  %if the closest tracker is within a predescribed distance, update that tracker
        Tracker{ActiveTrackers(loc)}.x(TrackerIndex(ActiveTrackers(loc))+1) = Tracker{ActiveTrackers(loc)}.x(TrackerIndex(ActiveTrackers(loc)))*StayingPower + TD.x(i)*(1-StayingPower);
        Tracker{ActiveTrackers(loc)}.y(TrackerIndex(ActiveTrackers(loc))+1) = Tracker{ActiveTrackers(loc)}.y(TrackerIndex(ActiveTrackers(loc)))*StayingPower + TD.y(i)*(1-StayingPower);
        Tracker{ActiveTrackers(loc)}.ts(TrackerIndex(ActiveTrackers(loc))+1) = TD.ts(i);
        Tracker{ActiveTrackers(loc)}.p(TrackerIndex(ActiveTrackers(loc))+1) = i;
        TrackerIndex(ActiveTrackers(loc)) = TrackerIndex(ActiveTrackers(loc))+1;
        C(i) = ActiveTrackers(loc);
    else %new tracker
        numTrackers = numTrackers+1;
        numActiveTrackers = numActiveTrackers+1;
        ActiveTrackers = [ActiveTrackers, numTrackers];
        TrackerIndex(numTrackers) = 1;
        Tracker{numTrackers}.x = zeros(1,30000);
        Tracker{numTrackers}.y = zeros(1,30000);
        Tracker{numTrackers}.ts = zeros(1,30000);
        Tracker{numTrackers}.p = zeros(1,30000);
        Tracker{numTrackers}.x(1) = TD.x(i);
        Tracker{numTrackers}.y(1) = TD.y(i);
        Tracker{numTrackers}.ts(1) = TD.ts(i);
        Tracker{numTrackers}.p(1) = i;
        C(i) = numTrackers;
    end
end

for j = 1:numActiveTrackers             %calculate the distance of current event to each tracker
    Tracker{ActiveTrackers(j)}.x(TrackerIndex(ActiveTrackers(j))+1:end) = [];
    Tracker{ActiveTrackers(j)}.y(TrackerIndex(ActiveTrackers(j))+1:end) = [];
    Tracker{ActiveTrackers(j)}.ts(TrackerIndex(ActiveTrackers(j))+1:end) = [];
    Tracker{ActiveTrackers(j)}.p(TrackerIndex(ActiveTrackers(j))+1:end) = [];
end