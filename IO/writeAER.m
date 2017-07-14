function writeAER(TD, EM, filename)
% writeAER(TD, EM, filename)
%   Saves events in the ".val" file formate used by the ATIS Windows GUI v4.2 onwards
%
% TAKES IN:
%   'filename'
%       A string specifying the name of the file to be written to. 
% 
%   'TD' 
%       A struct of "Temporal Difference" (TD) events with format
%           TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
%           TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%           TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
%                   events
%           TD.ts = event timestamps in microseconds
% 
%   'EM' 
%       A struct of grayscale "Exposure Measurement" events (EM events) with
%       format:
%           EM.x =  pixel X locations, strictly positive integers only (EM.x>0)
%           EM.y =  pixel Y locations, strictly positive integers only (EM.y>0)
%           EM.p =  event polarity. EM.p = 0 for first threshold, TD.p = 1 for
%                   second threshold
%           EM.ts = event timestamps in microseconds
% 
% 
% written by Garrick Orchard - July 2016
% garrickorchard@gmail.com

% combine the EM and TD events into a single stream, remembering the type
% of each
if isempty(TD) 
    AER = EM;
    AER.Type = ones(size(EM.ts));
elseif isempty(EM) 
    AER = TD;
    AER.Type = zeros(size(TD.ts));
else
    AER = CombineStreams(TD, EM, 'Type', 0, 1);
end

%how many counter overflows are we expecting
num_overflows = floor(AER.ts(end)/(2^13));

%initialize a struct for overflow events
ovf.ts = [1:num_overflows] .* 8192 - 1;
ovf.x = 306*ones(1,num_overflows);
ovf.y = 241*ones(1,num_overflows);
ovf.p = ones(1,num_overflows);
ovf.Type = zeros(1,num_overflows);

%find the overflow event locations
% for overflow_counter = 1:num_overflows
%     overflow_index = find(AER.ts>=(2^13)*overflow_counter, 1);
%     ovf.ts(overflow_counter) = AER.ts(overflow_index)-0.5;
% end

%combine the overflow events with the other AER events
AER = CombineStreams(AER, ovf);
AER.ts = ceil(AER.ts); %round the times
AER.ts = rem(AER.ts, 2^13); %make all times modulo 2^13

%create a new vector of uint8, with 4 bytes per event
event_stream = uint8(zeros(1,4*length(AER.ts)));

%place data into the vector
event_stream(4:4:end) = AER.y - 1;
event_stream(3:4:end) = bitand(AER.x - 1, 255);
event_stream(2:4:end) = bitshift(bitand(AER.x - 1, 256), -3);
event_stream(2:4:end) = event_stream(2:4:end) + uint8(bitshift(AER.p, 7));
event_stream(2:4:end) = event_stream(2:4:end) + uint8(bitshift(AER.Type, 6));
event_stream(2:4:end) = event_stream(2:4:end) + uint8(bitand(bitshift(AER.ts, -8), 31));

event_stream(1:4:end) = bitand(AER.ts, 255);

if ~isempty(strfind(filename, '.val'))
    val_file=fopen(filename,'w');
else
    val_file=fopen([filename, '.val'],'w');
end

 fwrite(val_file,event_stream,'uint8');
 fclose(val_file);