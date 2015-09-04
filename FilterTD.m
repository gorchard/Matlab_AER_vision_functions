% TDFiltered = FilterTD(TD, us_Time)
% A background activity filter.
% For each event, this function checks whether one of the 8 (vertical and
% horizontal) neighbouring pixels has had an event within the last
% 'us_Time' microseconds. If not, the event being checked will be
% considered as noise and removed
function TDFiltered = FilterTD(TD, us_Time)
j = 1;
T0 = zeros(304,240)*-inf;
X_prev = 0;
Y_prev = 0;
P_prev = 0;

TDFiltered.x = zeros(size(TD.x));
TDFiltered.y = zeros(size(TD.x));
TDFiltered.p = zeros(size(TD.x));
TDFiltered.ts = zeros(size(TD.x));

for i = 1:length(TD.ts)
    if X_prev ~= TD.x(i) || Y_prev ~= TD.y(i) || P_prev ~= TD.p(i)
        T0(TD.x(i), TD.y(i)) =  -inf;
        T0temp = T0(max((TD.x(i)-1),1):min((TD.x(i)+1), 304), max((TD.y(i)-1), 1):min((TD.y(i)+1),240));
        T0temp = T0temp(:);
        [mi, loc] = min(TD.ts(i)-T0temp);
        if  mi < us_Time
            TDFiltered.x(j) = TD.x(i);
            TDFiltered.y(j) = TD.y(i);
            TDFiltered.p(j) = TD.p(i);
            TDFiltered.ts(j) = TD.ts(i);
            j = j+1;
        end
        T0(TD.x(i), TD.y(i)) =  TD.ts(i);
        X_prev = TD.x(i);
        Y_prev = TD.y(i);
        P_prev = TD.p(i);
    end
end

TDFiltered = RemoveNulls(TDFiltered, TDFiltered.x == 0);