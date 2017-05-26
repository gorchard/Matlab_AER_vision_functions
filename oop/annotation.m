classdef annotation < handle
    %ANNOTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = public)
        filepath;
        comments;
        annotator;
        legend;
    end
    
    properties(SetAccess = protected)
        recording;
        picture;
        sensorWidth;
        sensorHeight;
        tracks = annotation_track.empty();
    end
    
    methods(Static)
        function anno = read_file(filename)
            if exist(filename, 'file') == 2
                fileID = fopen(filename, 'r');
                fscanf(fileID,'#This text file contains annotation data for recordings in: ');
                recording = fgetl(fileID); %for the newline character etc
                recording = strrep(recording, '\', filesep);
                recording = strrep(recording, '/', filesep);
                picture = fscanf(fileID, '#The corresponding picture of the recording site is at: %s');
                picture = strrep(picture, '\', filesep);
                picture = strrep(picture, '/', filesep);
                fgets(fileID); %for the newline character etc
                filepath = fscanf(fileID, '#The annotation file is stored at: %s');
                filepath = strrep(filepath, '\', filesep);
                filepath = strrep(filepath, '/', filesep);
                fgets(fileID); %for the newline character etc
                fscanf(fileID,'#Comments: ');
                comments = fgetl(fileID); %for the newline character etc
                annotator = fscanf(fileID,'#The recordings are annotated by: %s');
                fgets(fileID); %for the newline character etc
                sensorDimension = fscanf(fileID,'#Sensor Dimensions- Height = %d Pixels Width = %d Pixels');
                fgets(fileID); %for the newline character etc
                fscanf(fileID, '#LEGEND: ');
                legend = fgetl(fileID);
                fgets(fileID); %for the newline character etc
                
                anno = annotation(recording, picture, filepath, comments, annotator, sensorDimension(2), sensorDimension(1), legend);
                
                rawData = fscanf(fileID,'%u, %d, %d, %u, %u, %u, %u,\n', [7,inf])'; %7 columns, all rows
                if numel(rawData > 0)
                    annotationData.ts = double(rawData(:,1));
                    annotationData.x = single(rawData(:,2));
                    annotationData.y = single(rawData(:,3));
                    annotationData.xSize = single(rawData(:,4));
                    annotationData.ySize = single(rawData(:,5));
                    annotationData.trackNum = rawData(:,6);
                    annotationData.class = rawData(:,7);
                else
                    annotationData.ts = zeros(0, 'double');
                    annotationData.x = zeros(0, 'single');
                    annotationData.y = zeros(0, 'single');
                    annotationData.xSize = zeros(0, 'single');
                    annotationData.ySize = zeros(0, 'single');
                    annotationData.trackNum = zeros(0);
                    annotationData.class = zeros(0);
                end
                
                fclose(fileID);
                
                %get rid of 0s
                nullIndices = annotationData.trackNum == 0;
                annotationData.ts(nullIndices) = [];
                annotationData.x(nullIndices) = [];
                annotationData.y(nullIndices) = [];
                annotationData.xSize(nullIndices) = [];
                annotationData.ySize(nullIndices) = [];
                annotationData.trackNum(nullIndices) = [];
                annotationData.class(nullIndices) = [];
                
                %convert track data
                uniqueTrackNumbers = unique(annotationData.trackNum);
                validTrackCount = numel(uniqueTrackNumbers);
                anno.tracks = annotation_track.empty(validTrackCount, 0);
                
                for i = 1:numel(uniqueTrackNumbers)
                    extract = annotation.extract_raw_annotation_data(annotationData, uniqueTrackNumbers(i));
                    track = annotation_track(extract.class);
                    for j = 1:numel(extract.ts)
                        point = annotation_point(extract.x(j), extract.y(j) ,extract.xSize(j), extract.ySize(j), extract.ts(j));
                        track.add_point(point);
                    end
                    
                    anno.add_track(track);
                end
            else % file doesn't exist
                error('file %s does not exist', filename);
            end
        end
    end
    
    methods(Static, Access = private)
        function extract = extract_raw_annotation_data(annotationData, trackNum)
            % Creates a subset of this annotation which refers only to the
            % annotations for the specified track number
            indices = annotationData.trackNum == trackNum;
            if any(indices)
                extract.class = annotationData.class(indices);
                extract.class = extract.class(1);
                extract.x = annotationData.x(indices);
                extract.y = annotationData.y(indices);
                extract.xSize = annotationData.xSize(indices);
                extract.ySize = annotationData.ySize(indices);
                extract.ts = annotationData.ts(indices);
                
                [extract.ts, indices] = sort(extract.ts);
                extract.x = extract.x(indices);
                extract.y = extract.y(indices);
                extract.xSize = extract.xSize(indices);
                extract.ySize = extract.ySize(indices);
                extract.ts = extract.ts(indices);
            end
        end
    end
    
    methods(Access = public)
        function annotation = annotation(recording, picture, filepath, comments, annotator, sensorWidth, sensorHeight, legend)
            annotation.recording = recording;
            annotation.picture = picture;
            annotation.filepath = filepath;
            annotation.comments = comments;
            annotation.annotator = annotator;
            annotation.sensorWidth = sensorWidth;
            annotation.sensorHeight = sensorHeight;
            annotation.legend = legend;
        end
        
        function translate_time(annotation, translation)
            arrayfun(@(x) x.translate_time(translation), annotation.tracks);
        end
        
        function add_track(annotation, track)
            annotation.tracks(end+1) = track;
        end
        
        function isSuccess = delete_track(annotation, idx)
            isSuccess = 0;
            %remove track (by index) from this annotation
            if idx > 0 && idx <= numel(annotation.tracks)
                track = annotation.tracks(idx);
                annotation.tracks(idx) = [];
                delete(track);
                isSuccess = 1;
            end
        end
        
        function save(annotation)
            annoFilePath = annotation.filepath;
            annoFilePath = strrep(annoFilePath, '\', filesep);
            annoFilePath = strrep(annoFilePath, '/', filesep);
            pathstring = fileparts(annoFilePath);
            if ~isempty(pathstring) && ~exist(pathstring, 'dir')
                mkdir(pathstring);
            end
            
            %open the file
            annoFileHandle = fopen(annoFilePath, 'w');
            
            %write the header
            fprintf(annoFileHandle, '#This text file contains annotation data for recordings in: %s\n', annotation.recording);
            fprintf(annoFileHandle, '#The corresponding picture of the recording site is at: %s\n', annotation.picture);
            fprintf(annoFileHandle, '#The annotation file is stored at: %s\n', annotation.filepath);
            if isempty(annotation.comments)
                fprintf(annoFileHandle, '#Comments: %s\n', ' - ');
            else
                fprintf(annoFileHandle, '#Comments: %s\n', annotation.comments);
            end
            fprintf(annoFileHandle, '#The recordings are annotated by: %s\n', annotation.annotator);
            fprintf(annoFileHandle, '#Sensor Dimensions- Height = %d Pixels Width = %d Pixels\n', annotation.sensorHeight, annotation.sensorWidth);
            fprintf(annoFileHandle, '#LEGEND: %s\n', annotation.legend);
            fprintf(annoFileHandle, '#%s,%s,%s,%s,%s,%s,%s\n','Time(us)', 'x-Location', 'y-Location', 'x-size', 'y-size', 'track-num', 'class');
            
            %prepare the data
            endIdx = annotation.count_points();
            annoData.ts = zeros(1, endIdx);
            annoData.x = zeros(1, endIdx);
            annoData.y = zeros(1, endIdx);
            annoData.xSize = zeros(1, endIdx);
            annoData.ySize = zeros(1, endIdx);
            annoData.class = ones(1, endIdx);
            annoData.trackNum = zeros(1, endIdx);
            startIdx = 1;
            for i = 1:numel(annotation.tracks)
                track = annotation.tracks(i);
                endIdx = numel(track.points) + startIdx - 1;
                annoData.ts(startIdx:endIdx) = [track.points.ts];
                annoData.x(startIdx:endIdx) = [track.points.x];
                annoData.y(startIdx:endIdx) = [track.points.y];
                annoData.xSize(startIdx:endIdx) = [track.points.xSize];
                annoData.ySize(startIdx:endIdx) = [track.points.ySize];
                annoData.class(startIdx:endIdx) = track.class;
                annoData.trackNum(startIdx:endIdx) = i;
                startIdx = endIdx + 1;
            end
            
            %sort data by timestamp
            [annoData.ts, idx] = sort(annoData.ts);
            annoData.x = annoData.x(idx);
            annoData.y = annoData.y(idx);
            annoData.xSize = annoData.xSize(idx);
            annoData.ySize = annoData.ySize(idx);
            annoData.class = annoData.class(idx);
            annoData.trackNum = annoData.trackNum(idx);
            
            %write the data
            for i = 1:length(annoData.ts)
                fprintf(annoFileHandle, '%u, %d, %d, %u, %u, %u, %u, \n',annoData.ts(i), annoData.x(i), annoData.y(i), annoData.xSize(i), annoData.ySize(i), annoData.trackNum(i), annoData.class(i));
            end
            
            %close the file
            fclose(annoFileHandle);
        end
        
        function extract = extract_track(annotation, trackNum)
            % Creates a subset of this annotation which refers only to the
            % annotations for the specified track number
            if trackNum > numel(annotation.tracks) || trackNum <= 0
                extract = [];
            else
                track = annotation.tracks(trackNum);
                extract.class = track.class;
                extract.x = [track.points.x];
                extract.y = [track.points.y];
                extract.xSize = [track.points.xSize];
                extract.ySize = [track.points.ySize];
                extract.ts = [track.points.ts];
            end
        end
    end
    
    methods(Access = public)
        function numPoints = count_points(annotation)
            numPoints = sum(arrayfun(@(x) numel(x.points), annotation.tracks));
        end
    end
    
end

