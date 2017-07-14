function write_linux(td, filename, ~)
% write_linux(TD, filename, ~)
% writes data back to a ".bin" file format understood by the ATIS linux
% interface
%
% TAKES IN:
%   'td'
%       A struct of "Temporal Difference" (TD) events with format
%           td.x =  pixel X locations, strictly positive integers only (TD.x>0)
%           td.y =  pixel Y locations, strictly positive integers only (TD.y>0)
%           td.p =  event polarity. TD.p = 1 for OFF events, TD.p = 2 for ON
%                   events
%           td.ts = event timestamps in microseconds
%
%   'filename'
%       A string specifying the name of the file to be written. Typical filename
%       is "name.bin" for the linux interface
%
%   'events_per_packet'
%       Deprecated parameter. Used to be an integer specifying the number of events to write to each packet.
%       The linux interface processes packet-by-packet, but once in Matlab,
%       we do not keep record of how much data was in each packet received
%       by the sensor.
%
% written by Garrick Orchard - Feb 2016
% garrickorchard@gmail.com
%%

%open the file
outputFile = fopen(filename, 'w');

%write version header
fprintf(outputFile, 'v2\n');
%write a short header
fprintf(outputFile, '#Event file for linux_aer created using Matlab function "write_linux" at time %s \n', datestr(now));
%write the resolution of these events, followed by a newline
fwrite(outputFile, [max(td.x), max(td.y)], 'uint16');
% fwrite(outputFile, [304, 240], 'uint16');
%fwrite(outputFile, evt.height, 'uint32');
fprintf(outputFile, '\n');

writeEvents.x = double(td.x-1);
writeEvents.y = double(td.y-1);
writeEvents.ts = ceil(td.ts);
if any(strcmp('type',fieldnames(td)))
    writeEvents.type = td.type;
else
    writeEvents.type = zeros(1,length(td.ts));   
end

if any(strcmp('subtype',fieldnames(td)))
    writeEvents.subtype = td.subtype;
else
     writeEvents.subtype = td.p-1;
end

numEventsRemaining = length(writeEvents.ts);
%writeEvents.ts = rem(writeEvents.ts, 2^16);
packet_type = 1; %% TD_EM_Format

eventIdx = 1;
while numEventsRemaining >0
    startTime = bitshift(writeEvents.ts(eventIdx), -16);
    endTime = startTime+1;
    startTimeUs = bitshift(startTime, 16);
    endTimeUs = bitshift(endTime, 16);
    endIdx = find(writeEvents.ts < endTimeUs, 1, 'last');
    num_events = endIdx - eventIdx + 1;
    
    s = fwrite(outputFile, num_events, 'uint32');
    s = fwrite(outputFile, startTime, 'uint32');
%     s = fwrite(outputFile, endTime, 'uint32'); 
%% v2 Format is packet type and packet data instead of endtime
    s = fwrite(outputFile, packet_type, 'uint16');
    s = fwrite(outputFile, bitand(endTime, 2^16-1),'uint16');
%     

    
    writeEvents.ts(eventIdx:endIdx) = writeEvents.ts(eventIdx:endIdx) - startTimeUs;
    
    %num_events = bitshift(raw_data_buffer(buffer_location+3), 24) + bitshift(raw_data_buffer(buffer_location+2), 16) + bitshift(raw_data_buffer(buffer_location+1), 8) + raw_data_buffer(buffer_location);
    buffer = zeros(1, 8*num_events);
    buffer(1:8:end) = writeEvents.type(eventIdx:endIdx);
    buffer(2:8:end) = writeEvents.subtype(eventIdx:endIdx);
    buffer(3:8:end) = writeEvents.y(eventIdx:endIdx);
    buffer(5:8:end) = bitand(writeEvents.x(eventIdx:endIdx), 255, 'int32');
    buffer(6:8:end) = bitshift(writeEvents.x(eventIdx:endIdx), -8);
    buffer(7:8:end) = bitand(writeEvents.ts(eventIdx:endIdx), 255, 'int32');
    try
        buffer(8:8:end) = bitand(bitshift(writeEvents.ts(eventIdx:endIdx), -8), 255, 'uint32');
    catch e
        rethrow(e);
    end
    
    s = fwrite(outputFile, buffer, 'uint8');
    
    numEventsRemaining = numEventsRemaining - num_events;
    eventIdx = eventIdx + num_events;
end

fclose(outputFile);