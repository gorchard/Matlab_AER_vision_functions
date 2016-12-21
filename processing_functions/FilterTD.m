function TD = FilterTD(TD, us_Time)
% TDFiltered = FilterTD(TD, us_Time)
%   A background activity filter.
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
% written by Garrick Orchard - June 2014
% garrickorchard@gmail.com

TD.x = TD.x+1;
TD.y = TD.y+1;
TD.ts = TD.ts+1+us_Time;

xmax = max(TD.x);
ymax = max(TD.y);

T0 = zeros(xmax+1,ymax+1);

for i = 1:length(TD.ts)
    T0(TD.x(i), TD.y(i)) =  0;
    
    T0temp = T0((TD.x(i)-1):(TD.x(i)+1), (TD.y(i)-1):(TD.y(i)+1));
    T0(TD.x(i), TD.y(i)) =  TD.ts(i);
    
    if  TD.ts(i) >= max(T0temp(:)) + us_Time
        TD.ts(i) = 0;
    end
    
end

TD = RemoveNulls(TD, TD.ts == 0);
TD.x = TD.x-1;
TD.y = TD.y-1;
TD.ts = TD.ts-1-us_Time;