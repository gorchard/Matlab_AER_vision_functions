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

function TDout = ImplementRefraction(TDin, Refrac_time, Mutual_Refraction)

if ~exist('Mutual_Refraction', 'var')
    Mutual_Refraction = 0;
end

fieldnames = fields(TDin); %which fields are in the struct
for i = 1:length(fieldnames)
    TDout.(fieldnames{i})  =  []; %initialize TDout with the same field names
end

if Mutual_Refraction == 0
    polarities = unique(TDin.p);
    for k = 1:length(polarities)
        TD = RemoveNulls(TDin, TDin.p ~= polarities(k));
        LastTime = zeros(max(TD.x), max(TD.y));
        for i = 1:length(TD.ts)
            if ((TD.ts(i) - LastTime(TD.x(i), TD.y(i))) > Refrac_time) || (LastTime(TD.x(i), TD.y(i)) == 0)
                LastTime(TD.x(i), TD.y(i)) = TD.ts(i);
            else
                TD.ts(i) = 0;
            end
        end
        a = TD.ts == 0;
        TD = RemoveNulls(TD, a);
        TDout = CombineStreams(TDout, TD);
    end
else
    TD = TDin;
    LastTime = zeros(max(TD.x), max(TD.y));
    for i = 1:length(TD.ts)
        if ((TD.ts(i) - LastTime(TD.x(i), TD.y(i))) > Refrac_time) || (LastTime(TD.x(i), TD.y(i)) == 0)
            LastTime(TD.x(i), TD.y(i)) = TD.ts(i);
        else
            TD.ts(i) = 0;
        end
    end
    a = TD.ts == 0;
    TD = RemoveNulls(TD, a);
    TDout = CombineStreams(TDout, TD);
end