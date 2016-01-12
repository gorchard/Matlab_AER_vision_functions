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
TD = ExtractROI(TD, [1,1], [128,128]);
if length(TD.ts) ~= TDlength
    warning('jAER can only accept 128x128 pixel resolution, pixel addresses above 128x128 have been removed');
end

xshift=1; % bits to shift x to right
yshift=8; % bits to shift y to right

xfinal=bitshift(128-TD.x,xshift);
yfinal=bitshift(128-TD.y,yshift);

temp = unique(TD.p);
polfinal=ones(size(TD.p));
polfinal(TD.p == temp(1)) = 0;

vector_allAddr=uint32(yfinal+xfinal+polfinal);
vector_allTs=uint32(TD.ts);

aedat_file=fopen(filename,'w');

version=2;
fprintf(aedat_file,'%s','#!AER-DAT');
fprintf(aedat_file,'%1.1f\r\n', version);
fprintf(aedat_file,'%s\r\n','# This is a raw AE data file - do not edit');
fprintf(aedat_file,'%s\r\n','# Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event');
fprintf(aedat_file,'%s\r\n','# Timestamps tick is 1 us');
fprintf(aedat_file,'%s\r\n', ['# created ', datestr(now), ' by the Matlab function "write2jAER"']);

bof=ftell(aedat_file);
fseek(aedat_file,bof-4,'bof'); % start just after header
bof=ftell(aedat_file);

fwrite(aedat_file,vector_allAddr,'uint32',4,'b');
fseek(aedat_file,bof+4,'bof'); % timestamps start 4 after bof
fwrite(aedat_file,vector_allTs,'uint32',4,'b');
fclose(aedat_file);