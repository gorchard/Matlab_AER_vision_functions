function write2jAER(TD, filename)
% function write2jAER(TD, filename) 
%   Saves events in a format which can be read by jAER (http://sourceforge.net/p/jaer/wiki/Home/)
% 
% TAKES IN:
% 'TD' 
%       A struct of Temporal Difference (TD) events with format:
%           TD.x =  pixel X locations
%           TD.y =  pixel Y locations
%           TD.p =  event polarity
%           TD.ts = event timestamps in microseconds 
%
% 'filename'
%       The name of the file to be written
%
% This function does not return anything
% 
% 
% Adapted from the function "mat2dat", available from http://www2.imse-cnm.csic.es/caviar/MNIST_DVS/
% 
% Can only write a 128x128 pixel region for now
% 
% Garrick Orchard - June 2014
% garrickorchard@gmail.com

TDlength = length(TD.ts);
TD = ExtractROI(TD, [1,1], [640,480]);
if length(TD.ts) ~= TDlength
    warning('jAER can only accept 640x480 pixel resolution, pixel addresses above 640x480 have been removed');
end

% type = zeros(size(TD.ts));
% type_shift = 31;

y = 480-TD.y;
y_shift = 22;

x = 640-TD.x;
x_shift = 12;

p = TD.p;
p_shift = 11;

% trigger = zeros(size(TD.ts));
% trigger_shift = 10;

% ADC = zeros(size(TD.ts));
% ADC_shift = 0;

y_final=bitshift(y,y_shift); 
x_final=bitshift(x,x_shift); 
p_final=bitshift(p,p_shift); 

vector_allAddr=uint32(y_final+x_final+p_final);
vector_allTs=uint32(TD.ts);

aedat_file=fopen(filename,'w');

version=2;
fprintf(aedat_file,'%s','#!AER-DAT');
fprintf(aedat_file,'%1.1f\r\n', version);
fprintf(aedat_file,'%s\r\n','# This is a raw AE data file - do not edit');
fprintf(aedat_file,'%s\r\n','# Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event');
fprintf(aedat_file,'%s\r\n','# Timestamps tick is 1 us');
fprintf(aedat_file,'%s\r\n', ['# created ', datestr(now), ' by the Matlab function "write2jAER"']);
fprintf(aedat_file,'%s\r\n','# This function fakes the format of DAVIS640 to allow for the full ATIS address space to be used (304x240)');

bof=ftell(aedat_file);
fseek(aedat_file,bof-4,'bof'); % start just after header
bof=ftell(aedat_file);

fwrite(aedat_file,vector_allAddr,'uint32',4,'b');
fseek(aedat_file,bof+4,'bof'); % timestamps start 4 after bof
fwrite(aedat_file,vector_allTs,'uint32',4,'b');
fclose(aedat_file);