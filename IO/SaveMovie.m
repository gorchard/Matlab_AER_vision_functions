function SaveMovie(movie, filename, FPS)
% SaveMovie(movie, filename, FPS)
%   Writes a Matlab Movie object to file
% 
% Takes in a movie object , and write the movie as an uncompressed
% AVI file to "filename".avi
% FPS is an optional argument which defaults to 24
% 
% TAKES IN:
% 'movie'
%   A matlab movie object provided by one of the functions: 
%   "ShowTD", "ShowEM", and "ShowAPS"
% 
% 'filename'
%   The name of the movie file to write to. The output will be "filename".avi
% 
% 'FPS'
%   An optional argument stating the frame rate to be used. By default the
%   frame rate is 24 FPS (the same frame rate used by default for the
%   functions "ShowTD", "ShowEM", and "ShowAPS")
% 
% 
% The function does not return anything
% 
% 
% written by Garrick Orchard - June 2014
% garrickorchard@gmail.com 


if ~exist('FPS', 'var')
    FPS = 24; %default to 24FPS
end
    
%  writerObj = VideoWriter(filename, 'Uncompressed AVI');
 writerObj = VideoWriter(filename, 'Uncompressed AVI');
 writerObj.FrameRate = FPS;
 open(writerObj);
 writeVideo(writerObj,movie);
 close(writerObj);
end

