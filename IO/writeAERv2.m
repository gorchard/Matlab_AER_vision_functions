function writeAERv2(TD, EM, filename)
% writeAER(TD, EM, filename)
%   Saves events in the ".val_v2" file formate used by the ATIS FPGA Simulation for 64-bits data
% Code References from read_linux function in upstream repository
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
% written by Yanxian Du - July 2017
% duyanxian1990@gmail.com

if ~isempty(strfind(filename, '.val_v2'))
    val_file=fopen(filename,'w');
else
    val_file=fopen([filename, '.val_v2'],'w');
end

if isempty(TD)
    AER = EM;
    AER.Type = ones(size(EM.ts));
elseif isempty(EM)
    AER = TD;
    AER.Type = zeros(size(TD.ts));
else
    AER = CombineStreams(TD, EM, 'Type', 0, 1);
end

AER.p = AER.p - min(AER.p);

num_overflows = floor(AER.ts(end)/(2^16));

overflow_events.x       = zeros(1,num_overflows);
overflow_events.y       = zeros(1,num_overflows);
overflow_events.type    = 2*ones(1,num_overflows);
overflow_events.subtype = zeros(1,num_overflows);
overflow_events.ts      = (1:num_overflows)*(2^16)-0.5;

write_events.x = AER.x-1;
write_events.y = AER.y-1;
write_events.type = zeros(1,length(AER.ts));
write_events.subtype = AER.p;
write_events.ts = AER.ts;

write_events = CombineStreams(write_events, overflow_events);
write_events.ts = ceil(write_events.ts);
num_events = length(write_events.ts);

buffer = zeros(1, 8*num_events);
buffer(1:8:end) = write_events.type(1:num_events);
buffer(2:8:end) = write_events.subtype(1:num_events);
buffer(3:8:end) = write_events.y(1:num_events);
buffer(5:8:end) = bitand(write_events.x(1:num_events), 255, 'uint16');
buffer(6:8:end) = bitshift(write_events.x(1:num_events), -8);
buffer(7:8:end) = bitand(write_events.ts(1:num_events), 255, 'uint32');
buffer(8:8:end) = bitand(bitshift(write_events.ts(1:num_events), -8), 255, 'uint32');

fwrite(val_file, buffer, 'uint8');

fclose(val_file);