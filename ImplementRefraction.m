% TDout = ImplementRefraction(TDin, Refrac)
% implements a refractory period of 'Refrac' microseconds for each pixel.
% In other words, if an event occurs within 'Refrac' microseconds of
% a previous event at the same pixel, then the second event is removed
function TDout = ImplementRefraction(TDin, Refrac)

fieldnames = fields(TDin); %which fields are in the struct
for i = 1:length(fieldnames) 
    TDout.(fieldnames{i})  =  []; %initialize TDout with the same field names
end

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

