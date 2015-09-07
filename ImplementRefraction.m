% TDout = ImplementRefraction(TDin, Refrac, Mutual_Refraction)
% implements a refractory period of 'Refrac' microseconds for each pixel.
% In other words, if an event occurs within 'Refrac' microseconds of
% a previous event at the same pixel, then the second event is removed
%
% Mutual_Refraction is boolean, default = 0. Value 1 means that any polarity causes all
% polarities to enter refraction, while Value 0 means that each polarity is
% considered separate and independently of the others.
% i.e. if treating on and off polarities separate then set the
% Mutual_Refraction to 0 (default). If implementing a C1 style HFIRST
% layer, set Mutual_Refraction = 1

function TDout = ImplementRefraction(TDin, Refrac, Mutual_Refraction)

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
            if ((TD.ts(i) - LastTime(TD.x(i), TD.y(i))) > Refrac) || (LastTime(TD.x(i), TD.y(i)) == 0)
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
        if ((TD.ts(i) - LastTime(TD.x(i), TD.y(i))) > Refrac) || (LastTime(TD.x(i), TD.y(i)) == 0)
            LastTime(TD.x(i), TD.y(i)) = TD.ts(i);
        else
            TD.ts(i) = 0;
        end
    end
    a = TD.ts == 0;
    TD = RemoveNulls(TD, a);
    TDout = CombineStreams(TDout, TD);
end