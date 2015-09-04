function SaveMovie(movie, filename, FPS)
% SaveMovie(movie, filename, FPS)
% Takes in a movie object provided by one of the functions: 
% "ShowTD", "ShowEM", "ShowAPS", and write the movie as an uncompressed
% AVI file to "filename".avi
% FPS is an optional argument which defaults to 24



if ~exist('FPS', 'var')
    FPS = 24; %default to 24FPS
end
    
 writerObj = VideoWriter(filename, 'Uncompressed AVI');
 writerObj.FrameRate = FPS;
 open(writerObj);
 writeVideo(writerObj,movie);
 close(writerObj);
end

