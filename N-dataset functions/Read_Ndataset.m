% TD = Read_Ndataset(filename)
% returns the Temporal Difference (TD) events from binary file for the
% N-MNIST and N-Caltech101 datasets. See garrickorchard.com\datasets for
% more info
% 
% written by Garrick Orchard - July 2015
function TD = Read_Ndataset(filename)
eventData = fopen(filename);
evtStream = fread(eventData);
fclose(eventData);

TD.x    = uint16(evtStream(1:5:end)+1); %pixel x address, with first pixel having index 1
TD.y    = uint16(evtStream(2:5:end)+1); %pixel y address, with first pixel having index 1
TD.p    = uint8(bitshift(evtStream(3:5:end), -7)+1); %polarity, 1 means off, 2 means on
TD.ts   = bitshift(bitand(evtStream(3:5:end), 127), 16); %time in microseconds
TD.ts   = TD.ts + bitshift(evtStream(4:5:end), 8);
TD.ts   = uint32(TD.ts + evtStream(5:5:end));
return