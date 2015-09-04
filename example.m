%This script shows an example of reading in AER data and doing basic
%processing using some of the provided functions

%% read in data
% if data file is already in matlab format (.mat) then use
filename = 'example_data.mat'; % this file contains 3 seconds of both Exposure Measurement and Temporal Difference data
load(filename);

% if using N-MNIST or N-Caltech101, then instead use the Read_Ndataset function supplied with each dataset. 
% TD = Read_Ndataset(filename); (these datasets have no exposure measurement recordings)

% if reading in data recorded directly from the ATIS GUI, use:
% filename = 'GUI_output.val';
%[TD, EM] = ReadAER(filename);


% TD has fields: 
% TD.x (x pixel locations, starting from 1) 
% TD.y (y pixel locations, starting from 1) 
% TD.ts (event timestamps in microseconds)
% TD.p (event polarities, 0 for OFF-events, 1 for ON-events) 

% Similarly EM has fields: 
% EM.x (x pixel locations, starting from 1) 
% EM.y (y pixel locations, starting from 1) 
% EM.ts (event timestamps in microseconds)
% EM.p (event polarities, 0 for first threshold crossing, 1 for second threshold crossing)

%%
% To view a playback of the TD data, use:
ShowTD(TD); 
% type "help ShowTD" for more options

% To view a playback of the EM data, use:
ShowEM(EM); 
% type "help ShowEM" for more options

% To view a playback of both the TD and the EM data, use:
ShowTDEM(TD, EM); 
% type "help ShowTDEM" for more options

% To apply noise filtering to the TD data with 5ms history:
TD_filtered = FilterTD(TD, 5e3);

% view the result
ShowTD(TD_filtered);

% Show the data in a 3D space-time plot, the path of the bird and
% car should be clearly visible
Show3D(TD_filtered);

% Remove any events with y location greater than 120 (i.e. keep only the top
% half of the scene)
null_event_indices = TD_filtered.y>120;
TD_cropped = RemoveNulls(TD_filtered, null_event_indices);

% Extract a 50x50 pixel box with top left at location [250, 1], and only
% events occurring between 1 and 2 seconds
TD_ROI = ExtractROI(TD_cropped, [250,1], [50, 50], [1e6, 2e6]);

%Show the result 10x slowed down and make it into a movie
video = ShowTD(TD_ROI, 1/(24*10)); %a regular video would have 1/24 seconds worth of data per frame. We want 1/24 * 1/10 seconds of data per frame

SaveMovie(video, 'TD_ROI.AVI', 24); %24 FPS is the default used by ShowTD
%note that this movie will have no compression