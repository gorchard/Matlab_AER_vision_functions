function write_linux(TD, filename, events_per_packet)
% write_linux(TD, filename, events_per_packet)
% writes data back to a ".bin" file format understood by the ATIS linux
% interface
%
% TAKES IN:
%   'TD' 
%       A struct of "Temporal Difference" (TD) events with format
%           TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
%           TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%           TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
%                   events
%           TD.ts = event timestamps in microseconds
%
%   'filename'
%       A string specifying the name of the file to be written. Typical filename
%       is "name.bin" for the linux interface
%
%   'events_per_packet'
%       An integer specifying the number of events to write to each packet.
%       The linux interface processes packet-by-packet, but once in Matlab,
%       we do not keep record of how much data was in each packet received
%       by the sensor.
% 
% written by Garrick Orchard - Feb 2016
% garrickorchard@gmail.com
%%
if ~exist('events_per_packet', 'var')
    events_per_packet = 4096; %default to 2048 events per packet
end

%open the file
output_file = fopen(filename, 'w');

%write a short header
fprintf(output_file, '#Event file for linux_aer created using Matlab function "write_linux" at time %s \n\n', datestr(now));

num_overflows = floor(TD.ts(end)/(2^16));

overflow_events.x       = zeros(1,num_overflows);
overflow_events.y       = zeros(1,num_overflows);
overflow_events.type    = 2*ones(1,num_overflows);
overflow_events.subtype = zeros(1,num_overflows);
overflow_events.ts      = (1:num_overflows)*(2^16)-0.5;

write_events.x = TD.x-1;
write_events.y = TD.y-1;
write_events.type = zeros(1,length(TD.ts));
write_events.subtype = TD.p;
write_events.ts = TD.ts;

write_events = CombineStreams(write_events, overflow_events);
write_events.ts = ceil(write_events.ts);

if length(write_events.ts) ~= length(TD.ts) + num_overflows
    disp('error in calculating the number of overflow events')
end
num_events_remaining = length(write_events.ts);
%write_events.ts = rem(write_events.ts, 2^16);

event_index = 1;
while num_events_remaining >0
    num_events = min(events_per_packet, num_events_remaining);
    fwrite(output_file, num_events, 'uint32');
    fwrite(output_file, floor(write_events.ts(event_index)/2^16)*2^16, 'uint32');
%    fwrite(output_file, end_time, 'uint32');
    fwrite(output_file, floor(write_events.ts(event_index+num_events-1)/2^16)*2^16, 'uint32');

    %num_events = bitshift(raw_data_buffer(buffer_location+3), 24) + bitshift(raw_data_buffer(buffer_location+2), 16) + bitshift(raw_data_buffer(buffer_location+1), 8) + raw_data_buffer(buffer_location);
    buffer = zeros(1, 8*num_events);
    buffer(1:8:end) = write_events.type(event_index:(event_index+num_events-1));
    buffer(2:8:end) = write_events.subtype(event_index:(event_index+num_events-1));
    buffer(3:8:end) = write_events.y(event_index:(event_index+num_events-1));
    buffer(5:8:end) = bitand(write_events.x(event_index:(event_index+num_events-1)), 255, 'int32');
    buffer(6:8:end) = bitshift(write_events.x(event_index:(event_index+num_events-1)), -8);
    buffer(7:8:end) = bitand(write_events.ts(event_index:(event_index+num_events-1)), 255, 'int32');
    buffer(8:8:end) = bitand(bitshift(write_events.ts(event_index:(event_index+num_events-1)), -8), 255, 'uint32');
    
    fwrite(output_file, buffer, 'uint8');

    num_events_remaining = num_events_remaining - num_events;
    event_index = event_index + num_events;
end

fclose(output_file);