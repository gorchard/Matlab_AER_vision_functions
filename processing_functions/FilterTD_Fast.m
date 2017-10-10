function TD = FilterTD_Fast(TD, us_Time)
% TDFiltered = FilterTD_Fast(TD, us_Time)
%   A slightly faster version of FilterTD.m 
% 	Diff: Stores Max Time instead of extracting matrix then taking MAX op
%   For each event, this function checks whether one of the 8 (vertical and
%   horizontal) neighbouring pixels has had an event within the last
%   'us_Time' microseconds. If not, the event being checked will be
%   considered as noise and removed
% 
%   TAKES IN:
%   TD:     A struct of events with format
%       TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
%       TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%   	TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
%   	events
%       TD.ts = event timestamps in units of microseconds
% 
%   us_Time:    The time in microseconds within which a neighbouring pixel
%               must have generated an event for the current event to be
%               considered "signal" instead of "noise"
% 
%   RETURNS:
%   TDFiltered: A struct of the same format as "TD" but only containing
%               events which were not filtered out
% 
% written by Yanxian Du - Oct 2017
% yanxian@comp.nus.edu.sg

TD.x = TD.x+1;
TD.y = TD.y+1;
TD.ts = TD.ts+1+us_Time;

xmax = max(TD.x);
ymax = max(TD.y);

T0_max = zeros(xmax+1,ymax+1);
for i = 1:length(TD.ts)
    x = TD.x(i);
    y = TD.y(i);
    ts = TD.ts(i);
    
	prev_val = T0_max(x,y);
    for x_d = -1:1:1
        for y_d = -1:1:1
            T0_max(x+x_d,y+y_d) = max(T0_max(x+x_d,y+y_d), ts);
        end
    end
    T0_max(x,y) = prev_val;
    
    if  ts >= T0_max(x,y) + us_Time
        TD.ts(i) = 0;
    end
    
end

TD = RemoveNulls(TD, TD.ts == 0);
TD.x = TD.x-1;
TD.y = TD.y-1;
TD.ts = TD.ts-1-us_Time;
