% TDout =  RemoveNulls(TD, Null_indices)
% removes all events at the logical indices 'Null_indices'
% example use to remove all events at pixel location (3,5):
%
% Null_indices = (TD.x == 3) && (TD.y == 5)
%
% newTD =  RemoveNulls(TD, Null_indices)
function result =  RemoveNulls(result, indices)
fieldnames = fields(result);
for i = 1:length(fieldnames)
    result.(fieldnames{i})(indices)  = [];
end