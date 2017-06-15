%This script shows an example of reading in AER data and doing basic
%processing using some of the provided functions

% if using N-MNIST or N-Caltech101, use the ndataset_events to read the file
width = 34; %N-MNIST
height = 34; %N-MNIST
% td = ndataset_events(width, height, filename); %(these datasets have no exposure measurement recordings)

% to stabilize the N-MNIST / N-Caltech101 recordings,
% td.stabilize();

% If reading bin data, use:
% filename = '1.bin';
[td, em, others] = base_events.read_linux(filename);

% if reading in data recorded directly from the ATIS GUI, use:
% filename = 'GUI_output.val';
%[TD, EM] = base_events.read_aer(filename, width, height);


% base_events has public fields: 
% x (x pixel locations, starting from 1) 
% y (y pixel locations, starting from 1) 
% ts (event timestamps in microseconds)
% p (event polarities, 0 for OFF-events, 1 for ON-events) 
% comments - optional
% annotation - optional

% Similarly EM has fields: 
% EM.x (x pixel locations, starting from 1) 
% EM.y (y pixel locations, starting from 1) 
% EM.ts (event timestamps in microseconds)
% EM.p (event polarities, 0 for first threshold crossing, 1 for second threshold crossing)

%%
% To view a playback of the TD data, use:
vid = td.show(timePerFrame, frameLength, startTime, stopTime); % type "help ShowTD" for more options
%or
frameDuration = 33333; %microseconds of data per frame
isDisplay = 1; %if only interested in saving as an avi without displaying, set to 0;
%saveFileName is optional. If provided, it saves to the td as an avi file.
frames = td.show_grayscale(frameDuration, isDisplay, saveFileName);


% To view a playback of the EM data, use:
ShowEM(EM); 
% type "help ShowEM" for more options

% to make a copy of the td data, use
tdCopy = td.clone();

% To apply noise filtering directly to the TD data with 5ms history:
tdCopy.filter(5e3);

% view the result
tdCopy.show_grayscale(frameDuration, isDisplay);

% Remove any events with y location greater than 120 (i.e. keep only the top
% half of the scene)
tdCropped = tdCopy.clone();
indicesToRemove = tdCropped.y > 120;
tdCropped.remove_events(indicesToRemove);


% Extract a 50x50 pixel box with top left at location [250, 1]
tdRoi = tdCropped.clone();
isNormalize = 1;
tdRoi.extract_roi(250, 1, 50, 50, isNormalize);
% extract events occurring between 1 and 2 seconds
tdRoi.extract_time(1e6, 2e6);

%Show the result 10x slowed down and make it into a movie
video = tdRoi.show(1/(24*10)); %a regular video would have 1/24 seconds worth of data per frame. We want 1/24 * 1/10 seconds of data per frame

SaveMovie(video, 'TD_ROI.AVI', 24); %24 FPS is the default used by ShowTD
%note that this movie will have no compression

% base_events and ndataset_events contain many more methods for
% manipulating the events data. base_events also contains a useful static
% method for reading annotations with the corresponding td data.