function [comments, dimensions] = read_linux_header(filename)
% [comments, dimensions] = read_linux_header(filename)
% Reads in data the comments and dimensions from the file in question
%
% TAKES IN:
%   'filename'
%       A string specifying the name of the file to be read. Typical filename
%       is "*.bin"
% 
% RETURNS:
%   'comments' 
%       A single line string containing the comments from the file
% 
%   'dimensions' 
%       [x, y] dimensions of the sensor
%
% written by Garrick Orchard - Dec 2016
% garrickorchard@gmail.com
%%
videoData = fopen(filename);

% skip through the header lines
temp = fgetl(videoData);
comments = [];
dimensions = [];
while ~isempty(temp)
    if temp(1) == '#'
        comments = [comments, temp];
        temp = fgetl(videoData);
    else
        dimensions = temp;
        temp = [];
    end
end

if isempty(dimensions)
    fprintf('No dimensions in input file, resorting to ATIS default of [304 x 240]');
    dimensions = [304, 240]; %default to ATIS dimensions since all recordings before including dimensions were with ATIS
end