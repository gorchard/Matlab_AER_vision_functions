%NewStream = CombineStreams(Stream1, Stream2, newFieldName, newFieldVal1, newFieldVal2)
%combines two event streams (Stream1 and Stream2)
%For example, two TD events streams (TD1 and TD2) can be overlayed for
%testing noise, where TD1 is signal and TD2 is noise
%
% below arguments are optional, they allow creation of a new field in the
% struct to track which events originated from which input stream
%
% newFieldName - a string giving a name to a new field for the 'NewStream'
% struct
%
% newFieldVal1 - the value for the new field for events originating from
% Stream1
%
% newFieldVal2 - the value for the new field for events originating from
% Stream2
%
% 

function Stream1 = CombineStreams(Stream1, Stream2, newFieldName, newFieldVal1, newFieldVal2)

% check the field names
fieldnames = fields(Stream1);
fieldnames2 = fields(Stream2);

% make sure they are all row vectors (not column vectors)
for i = 1:length(fieldnames)
    [numRows,~] = size(Stream1.(fieldnames{i}));
    if numRows>1
        Stream1.(fieldnames{i}) = Stream1.(fieldnames{i})';
    end
end

for i = 1:length(fieldnames2)
    [numRows,~] = size(Stream2.(fieldnames2{i}));
    if numRows>1
        Stream2.(fieldnames2{i}) = Stream2.(fieldnames2{i})';
    end
end



if exist('newFieldName', 'var')
    Stream1.(newFieldName)  =  [newFieldVal1*ones(size(Stream1.(fieldnames{1}))), newFieldVal2*ones(size(Stream2.(fieldnames{1})))];
end

if ~isempty(Stream2)
    for i = 1:length(fieldnames)
        if isfield(Stream2, fieldnames{i})
            Stream1.(fieldnames{i})  =  [Stream1.(fieldnames{i}), Stream2.(fieldnames{i})];
        else
            Stream1.(fieldnames{i})  =  [Stream1.(fieldnames{i}), zeros(size(Stream2.(fieldnames2{1})))];
        end
    end
end

if isfield(Stream1, 'TimeStamp') || isfield(Stream1, 'ts')
    Stream1 = SortOrder(Stream1);
end