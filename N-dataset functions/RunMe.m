% An example script showing how to read in a recording, the contour of
% the object, and display the output
% 
% written by Garrick Orchard - July 2015


% This is the name of the file from the TD recording
TD_filename = 'Caltech101\butterfly\image_0001.bin'; 

% This is the name of the file containing the object contour/annotation
contour_filename = 'Caltech101_annotations\butterfly\annotation_0001.bin';

%read in the recording
TD = Read_Ndataset(TD_filename);

%read in the object outline
[box, obj] = Read_annotation(contour_filename);

%show the data and bounding box at 0.005s (5ms) per frame (i.e. slow
%motion)
ShowTDcontour(TD, box, 0.005);

%show the data and object contour at 0.005s (5ms) per frame (i.e. slow
%motion)
ShowTDcontour(TD, box, 0.005);

%show just the data at 0.005s (5ms) per frame (i.e. slow motion)
ShowTD(TD, 0.005);

%show just the data at 0.01s (10ms) per frame (i.e. slow motion)
ShowTD(TD, 0.01);

