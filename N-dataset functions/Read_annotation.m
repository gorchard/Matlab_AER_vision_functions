function [box_contour, obj_contour] = Read_annotation(filename)
% [box_contour, obj_contour] = Read_annotation(filename)
% reads in the bounding box ('box_contour') and object contour
% ('obj_contour') from the specified file ('filename')
% 
% A typical filename is 'annoation_0001.bin'
% 
% written by Garrick Orchard - July 2015
% 
% The boundaries/contours are based on the original Caltech101 annotations by Fei-Fei Lee

FID = fopen(filename);
rows = fread(FID, 1, 'int16');
cols = fread(FID, 1, 'int16');
box_contour = fread(FID, rows*cols, 'int16');
box_contour = reshape(box_contour, [rows, cols]);

rows = fread(FID, 1, 'int16');
cols = fread(FID, 1, 'int16');
obj_contour = fread(FID, rows*cols, 'int16');
obj_contour = reshape(obj_contour, [rows, cols]);

fclose(FID);
