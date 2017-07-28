% TDout = ImplementRefraction(TDin, Refrac_time, Mutual_Refraction)
%   Implements a refractory period for each pixel.
%   In other words, if an event occurs within 'Refrac_time' microseconds of
%   a previous event at the same pixel, then the second event is removed
%
% TAKES IN:
% 'TDin'
%   A struct of events with format:
%       TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
%       TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%   	TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
%   	events
%       TD.ts = event timestamps, typically in units of microseconds
%
% 'Refrac_time'
%   The refractory period in the same units as 'TD.ts'
%
% 'Mutual_Refraction'
%   A boolean flag indicating whether refraction is applied separately
%   to each polarity.
%       Mutual_Refraction = 0   means that refraction is applied separately
%                               to each polarity
%       Mutual_Refraction = 1   means that polarity is completely ignored
%                               by the function when implementing
%                               refraction
%
% RETURNS:
% 'TDout'
%   A struct with the same format as 'TDin', but with the refractory period
%   implemented (i.e. if two events occur at the same pixel within a time
%   period of 'Refrac_time' then the second event is removed).
%
%
% written by Garrick Orchard - June 2014
% garrickorchard@gmail.com

function TD = ImplementRefraction(TD, Refrac_time, Mutual_Refraction)
min_time = min(TD.ts);
TD.ts = TD.ts + Refrac_time + 1 - min_time;

if ~exist('Mutual_Refraction', 'var')
    Mutual_Refraction = 1;
end

if Mutual_Refraction == 0
    min_polarity = min(TD.p);
    TD.p = TD.p - min_polarity + 1;
    max_polarity = max(TD.p);
    LastTime = zeros(max(TD.x), max(TD.y), max_polarity);
    for i = 1:length(TD.ts)
        if ((TD.ts(i) - LastTime(TD.x(i), TD.y(i), TD.p(i))) > Refrac_time)
            LastTime(TD.x(i), TD.y(i), TD.p(i)) = TD.ts(i);
        else
            TD.ts(i) = 0;
        end
    end
    TD = RemoveNulls(TD, TD.ts == 0);
    TD.p = TD.p + min_polarity - 1;
else
    LastTime = zeros(max(TD.x), max(TD.y));
    for i = 1:length(TD.ts)
        if ((TD.ts(i) - LastTime(TD.x(i), TD.y(i))) > Refrac_time)
            LastTime(TD.x(i), TD.y(i)) = TD.ts(i);
        else
            TD.ts(i) = 0;
        end
    end
    TD = RemoveNulls(TD, TD.ts == 0);
end

TD.ts = TD.ts - Refrac_time - 1 + min_time;