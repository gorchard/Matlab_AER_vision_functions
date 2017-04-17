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

%% is the first line a header or a version specifier?
temp = fgetl(videoData);
comments = [];

if temp(1) == '#'
    file_version = 0;
    comments = temp;
elseif temp(1) == 'v'
    file_version = str2double(temp(2:end));
end
%fprintf('File is version %i\n', file_version);

%% skip through the rest of the comments
file_position = ftell(videoData); %remember the current position before reading in the new line
isContinue = 1;
while isContinue
    temp = fgetl(videoData);
    if isempty(temp)
        isContinue = 0;
        file_position = ftell(videoData); %remember the current position before reading in the new line
    elseif temp(1) == '#'
        if isempty(comments)
            comments = temp;
        else
            comments = strcat(comments, 10, temp);
        end
        file_position = ftell(videoData); %remember the current position before reading in the new line
    else
        isContinue = 0;
    end
end
fseek(videoData, file_position, 'bof'); %rewind back to the start of the first non-comment line

%% get the sensor resolution
if file_version == 0
    dimensions = [304,240];
else
    dimensions = fread(videoData, 2, 'uint16');
    fgetl(videoData);
end