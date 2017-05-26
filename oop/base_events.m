
classdef base_events < handle
    %temporal difference (td) / exposure measurement (em) events
    %   4 main properties are x, y, p and ts which are arrays of integers
    
    properties(SetAccess = public)
        x; %array of event x addresses
        
        y; %array of event y addresses
        
        p; %array of event polarities. 0 for OFF events, 1 for ON events
        
        ts; %array of event timestamps in microseconds
        
        comments; %
        
        annotation; % Annotation associated with this set of base events
    end
    
    properties(SetAccess = protected)
        width; %width of the frame
        
        height; %height of the frame
        
        actualSize; %actual number of events (disregarding pre-allocated size)
    end
    
    methods(Static)
        function [td, em, others] = read_linux(filename)
            videoData = fopen(filename, 'r');
            try
                comments = [];
                %% is the first line a header or a version specifier?
                temp = fgetl(videoData);
                if temp(1) == '#'
                    fileVersion = 0;
                    comments = temp;
                elseif temp(1) == 'v'
                    fileVersion = str2double(temp(2:end));
                end
                fprintf('%s is version %i\n', filename, fileVersion);
                
                %% skip through the rest of the comments
                filePosition = ftell(videoData); %remember the current position before reading in the new line
                isContinue = 1;
                while isContinue
                    temp = fgetl(videoData);
                    if isempty(temp)
                        isContinue = 0;
                        filePosition = ftell(videoData); %remember the current position before reading in the new line
                    elseif temp(1) == '#'
                        if isempty(comments)
                            comments = temp;
                        else
                            comments = strcat(comments, 10, temp);
                        end
                        filePosition = ftell(videoData); %remember the current position before reading in the new line
                    else
                        isContinue = 0;
                    end
                end
                fseek(videoData, filePosition, 'bof'); %rewind back to the start of the first non-comment line
                
                %% get the sensor resolution
                if fileVersion == 0
                    width = 304;
                    height = 240;
                else
                    resolution = fread(videoData, 2, 'uint16');
                    width = resolution(1);
                    height = resolution(2);
                    temp = fgetl(videoData);
                end
                %fprintf('Resolution is [%i, %i]\n', width, height);
                % start_offset = ftell(videoData);
                %
                % total_events = 0;
                % %make the ATIS interface write the final number of events at the end of the
                % %file so we can avoid this procedure
                % while ~feof(videoData)
                %     num_events = fread(videoData, 1, 'int32'); %number of bytes in this packet
                %     if ~feof(videoData)
                %         fseek(videoData, 8+8*num_events, 'cof');
                %         total_events = total_events + num_events;
                %     end
                % end
                
                %initialize TD struct
                fileinfo = dir(filename);
                estimateSize = ceil(fileinfo.bytes / 8);
                TDtemp.x = zeros(1,estimateSize, 'single');
                TDtemp.y = zeros(1,estimateSize, 'single');
                TDtemp.p = zeros(1,estimateSize, 'uint8');
                TDtemp.ts = zeros(1,estimateSize, 'double');
                TDtemp.type = inf*ones(1,estimateSize, 'uint8');
                %TD_indices = logical(zeros(1,total_events));
                raw_data_buffer = uint8(fread(videoData));
                
                %packet_num = 1;
                %read one packet at a time until the end of the file is reached
                total_events = 1;
                buffer_location = 1;
                while buffer_location < length(raw_data_buffer)
                    num_events = bitshift(uint32(raw_data_buffer(buffer_location+3)), 24) + bitshift(uint32(raw_data_buffer(buffer_location+2)), 16) + bitshift(uint32(raw_data_buffer(buffer_location+1)), 8) + uint32(raw_data_buffer(buffer_location));
                    %fprintf('%d, %d, %d, %d, numEvents: %d\n', raw_data_buffer(buffer_location+3), raw_data_buffer(buffer_location+2), raw_data_buffer(buffer_location+1), raw_data_buffer(buffer_location), num_events);
                    buffer_location = buffer_location +4;
                    start_time = bitshift(uint32(raw_data_buffer(buffer_location+3)), 24) + bitshift(uint32(raw_data_buffer(buffer_location+2)), 16) + bitshift(uint32(raw_data_buffer(buffer_location+1)), 8) + uint32(raw_data_buffer(buffer_location));
                    if fileVersion ~= 0
                        start_time = bitshift(start_time, 16);
                    end
                    
                    buffer_location = buffer_location + 8; %skip the end_time
                    
                    type = raw_data_buffer(buffer_location:8:(buffer_location+8*(num_events-1)));
                    subtype = raw_data_buffer((buffer_location+1):8:(buffer_location+8*(num_events)));
                    y = uint16(raw_data_buffer((buffer_location+2):8:(buffer_location+8*(num_events)+1))) + 256*uint16(raw_data_buffer((buffer_location+3):8:(buffer_location+8*(num_events)+1)));
                    x = bitshift(uint16(raw_data_buffer((buffer_location+5):8:(buffer_location+8*(num_events)+4))), 8) + uint16(raw_data_buffer((buffer_location+4):8:(buffer_location+8*(num_events)+3)));
                    ts = bitshift(uint32(raw_data_buffer((buffer_location+7):8:(buffer_location+8*(num_events)+6))), 8) + uint32(raw_data_buffer((buffer_location+6):8:(buffer_location+8*(num_events)+5)));
                    
                    buffer_location = buffer_location + num_events*8;
                    ts = ts + start_time;
                    %packet_num = packet_num + 1;
                    if fileVersion == 0
                        overflows = find(type == 2);
                        for i = 1:length(overflows)
                            ts(overflows(i):end) = ts(overflows(i):end) + 65536;
                        end
                    end
                    
                    TDtemp.type(total_events:(total_events+num_events-1)) = type;
                    TDtemp.x(total_events:(total_events+num_events-1)) = x;
                    TDtemp.y(total_events:(total_events+num_events-1)) = y;
                    TDtemp.p(total_events:(total_events+num_events-1)) = subtype;
                    TDtemp.ts(total_events:(total_events+num_events-1)) = ts;
                    %TDtemp.f(total_events:(total_events+num_events-1)) = type;
                    total_events = total_events + num_events;
                end
                
                TDtemp.type(total_events:end) = [];
                TDtemp.x(total_events:end) = [];
                TDtemp.y(total_events:end) = [];
                TDtemp.p(total_events:end) = [];
                TDtemp.ts(total_events:end) = [];
                
                [TDtemp.ts, ordering] = sort(TDtemp.ts);
                TDtemp.type = TDtemp.type(ordering);
                TDtemp.x = TDtemp.x(ordering);
                TDtemp.y = TDtemp.y(ordering);
                TDtemp.p = TDtemp.p(ordering);
                clear raw_data_buffer type x y subtype ts
            catch e
                clear raw_data_buffer type x y subtype ts
                rethrow e;
            end
            
            fclose(videoData);
            
            if exist('TDtemp', 'var')
                td = base_events(width, height);
                td.x = TDtemp.x(ordering);
                td.y = TDtemp.y(ordering);
                td.p = TDtemp.p(ordering);
                td.ts = TDtemp.ts;
                td.actualSize = numel(td.x);
                td.comments = comments;
                nullIndices = isinf(TDtemp.type);
                td.remove_events(nullIndices);
                em = td.clone();
                others = td.clone();
                
                TDtemp.type(nullIndices) = [];
                td.remove_events((TDtemp.type ~= 0) & (TDtemp.type ~=3));
                em.remove_events(TDtemp.type ~= 1);
                others.remove_events(TDtemp.type < 4);
                
                td.x = td.x+1;
                td.y = td.y+1;
                td.p = td.p+1;
                
                em.x = em.x +1;
                em.y = em.y +1;
            end
        end
        
        function [td, em] = read_aer(filename, width, height)
            % [TD, EM] = ReadAER(filename)
            % Reads in data from a ".val" file generated by the ATIS GUI v4.2 onwards
            %
            % TAKES IN:
            %   'filename'
            %       A string specifying the name of the file to be read. Typical filename
            %       is "0000.val" if generated by the ATIS GUI
            %
            % RETURNS:
            %   'TD'
            %       A struct of "Temporal Difference" (TD) events with format
            %           TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
            %           TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
            %           TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
            %                   events
            %           TD.ts = event timestamps in microseconds
            %
            %   'EM'
            %       A struct of grayscale "Exposure Measurement" events (EM events) with
            %       format:
            %           EM.x =  pixel X locations, strictly positive integers only (EM.x>0)
            %           EM.y =  pixel Y locations, strictly positive integers only (EM.y>0)
            %           EM.p =  event polarity. EM.p = 0 for first threshold, TD.p = 1 for
            %                   second threshold
            %           EM.ts = event timestamps in microseconds
            %
            % If reading in datasets (N-Caltech101 or N-MNIST) use the functions
            % included with the dataset instead.
            %
            %
            % written by Garrick Orchard - June 2014
            % garrickorchard@gmail.com
            td = base_events(width, height);
            videoData = fopen(filename);
            temp = fread(videoData);
            fclose(videoData);
            td.y = 1+ temp(4:4:end);
            td.x = 1+ bitshift(bitand(temp(2:4:end),32),3)  + temp(3:4:end); %bit 5
            td.p = bitshift(bitand(temp(2:4:end), 128), -7); %bit 7
            Type = bitshift(bitand(temp(2:4:end), 64), -6); %bit 6
            td.ts = temp(1:4:end) + bitshift((bitand(temp(2:4:end), 31)), 8);% bit 4 downto 0
            
            timeOffset = 0;
            for i = 1:length(td.ts)
                if ((td.y(i) == 241) && (td.x(i) ==306))
                    Type(i) = 2;
                    timeOffset = timeOffset + 2^13;
                else
                    td.ts(i) = td.ts(i) + timeOffset;
                end
            end
            
            td.remove_events(Type == 2);
            Type = Type(Type ~= 2);
            
            em = td.clone();
            em.remove_events(Type == 0);
            td.remove_events(Type == 1);
        end
        
        function [td, em, others] = read_annotated_td(annotationFilename, datasetDirectory)
            annoFilePath = strrep(annotationFilename, '\', filesep);
            annoFilePath = strrep(annoFilePath, '/', filesep);
            anno = annotation.read_file(annoFilePath);
            
            datasetDir = strrep(datasetDirectory, '\', filesep);
            datasetDir = strrep(datasetDir, '/', filesep);
            if datasetDir(end) == filesep
                tdFileName = strcat(datasetDir, anno.recording);
            else
                tdFileName = strcat(datasetDir, filesep, anno.recording);
            end
            
            [td, em, others] = base_events.read_linux(tdFileName);
            em.annotation = anno;
            td.annotation = anno;
            
        end
        
%         function [td, em, others] = read_annotated_td(annotationFilename, datasetDirectory)
%             anno = annotation(annotationFilename);
%                         
%             if datasetDirectory(end) == '\' || datasetDirectory(end) == '/'
%                 tdFileName = strcat(datasetDirectory, anno.meta.source);
%             else
%                 tdFileName = strcat(datasetDirectory, '/', anno.meta.source);
%             end
%             tdFileName = strrep(tdFileName, '\', '/');
%             [td, em, others] = base_events.read_linux(tdFileName);
%             em.annotation = anno;
%             td.annotation = anno;
%         end
    end
    
    methods(Access = public)
        function evt = base_events(width, height)
            evt.width = width;
            evt.height = height;
        end
        
        function set_events_data(evt, x, y, p, ts, actualSize)
            % Modify the base_event's event data
            
            if (numel(x) ~= numel(y)) ||  (numel(p) ~= numel(ts)) || (numel(x) ~= numel(p))
                error('Number of elements in x, y, p and ts must be the same! %d, %d, %d, %d', numel(x), numel(y), numel(p), numel(ts));
            end
            
            if actualSize > numel(x)
                error('Actual Size (%d) should not exceed number of events (%d)', actualSize, numel(x));
            end
            
            evt.x = x;
            evt.y= y;
            evt.p = p;
            evt.ts = ts;
            evt.actualSize = actualSize;
        end
        
        function preallocate(evt, numberToAdd)
            %pre-allocate additional space for new data
            newSpace = zeros(numberToAdd, 1);
            evt.x = [evt.x; newSpace];
            evt.y = [evt.y; newSpace];
            evt.p = [evt.p; newSpace];
            evt.ts = [evt.ts; newSpace];
        end
        
        function trim(evt)
            %remove unused portions of the x, y, ts, p arrays
            if (numel(evt.x) > evt.actualSize)
                evt.x = evt.x(1:evt.actualSize);
                evt.y = evt.y(1:evt.actualSize);
                evt.ts = evt.ts(1:evt.actualSize);
                evt.p = evt.p(1:evt.actualSize);
            end
        end
        
        function concatenate(evt, eventsToAdd)
            % Concatenate eventsToAdd to this base_events instance
            % eventsToAdd is also an instance of base_events
            newEventsSize = numel(eventsToAdd.x);
            if (evt.actualSize + newEventsSize) > numel(evt.x)
                evt.preallocate(newEventsSize);
            end
            
            startIdx = evt.actualSize + 1;
            endIdx = evt.actualSize + newEventsSize;
            
            evt.x((startIdx):(endIdx)) = eventsToAdd.x;
            evt.y((startIdx):(endIdx)) = eventsToAdd.y;
            evt.p((startIdx):(endIdx)) = eventsToAdd.p;
            evt.ts((startIdx):(endIdx)) = eventsToAdd.ts;
            evt.actualSize = endIdx;
        end
        
        function filter(evt, usTime)
            %   Apply background activity filter.
            %   For each event, this function checks whether one of the 8 (vertical and
            %   horizontal) neighbouring pixels has had an event within the last
            %   'usTime' microseconds. If not, the event being checked will be
            %   considered as noise and removed
            %
            %   TAKES IN:
            %   evt: base_events instance
            %
            %   usTime:    The time in microseconds within which a neighbouring pixel
            %               must have generated an event for the current event to be
            %               considered "signal" instead of "noise"
            %
            % written by Garrick Orchard - June 2014
            % garrickorchard@gmail.com
            if (numel(evt.x) > evt.actualSize)
                error('Cannot perform filtering if events are not trimmed\n');
            end
            
            tempHeight = evt.height;
            tempWidth = evt.width;
            currentFrame = ones(tempHeight, tempWidth)*-inf;
            noiseIndices = zeros(numel(evt.ts), 1, 'logical');
            
            for i = 1:length(evt.ts)
                tempX = evt.x(i);
                tempY = evt.y(i);
                tempTs = evt.ts(i);
                currentFrame(tempY, tempX) = tempTs;
                minTs = min(min(currentFrame(max(1, tempY-1):min(tempHeight, tempY+1), max(1, tempX-1):min(tempWidth, tempX+1))));
                if tempTs - minTs > usTime
                    noiseIndices(i) = 1;
                end
            end
            
            evt.remove_events(noiseIndices);
        end
        
        function extract_roi(evt, top, left, width, height, isNormalize)
            % extract_roi(top, left, width, height, isNormalize)
            %   Extracts a spatio-temporal Region Of Interest (ROI) from the events
            %
            % TAKES IN:
            % 'top' and 'left'
            %       The top left corner of the spatial ROI in pixels. Leave empty
            %       if only a temporal ROI is required.
            %
            % 'width' and 'height'
            %        The spatial size of the ROI in pixels. Leave empty if only a
            %        temporal ROI is required.
            %
            % 'isNormalize'
            %       1 if the x and y coordinates should be shifted by [-top, -left] after
            %       the region has been extracted. This will also adjust
            %       the width and height of the td.
            %       0 if the x, y coordinates of events, and width and
            %       height should remain unchanged.
            if (numel(evt.x) > evt.actualSize)
                error('Cannot extract roi if events are not trimmed\n');
            end
            
            indicesToRemove = (evt.x <= left) | evt.y <= top | evt.x > (left + width) | evt.y > (top + height);
            evt.remove_events(indicesToRemove);
            
            if isNormalize
                evt.x = evt.x - left;
                evt.y = evt.y - top;
                evt.width = width;
                evt.height = height;
            end
        end
        
        function apply_refraction(evt, refracTime, isAccountForPolarity)
            %   Implements a refractory period for each pixel.
            %   In other words, if an event occurs within 'refracTime' microseconds of
            %   a previous event at the same pixel, then the second event is removed
            %
            % TAKES IN:
            % 'TDin'
            %   A struct of events with format:
            %       TD.x =  pixel X locations, strictly positive integers only (TD.x>0)
            %       TD.y =  pixel Y locations, strictly positive integers only (TD.y>0)
            %   	TD.p =  event polarity. TD.p = 0 for OFF events, TD.p = 1 for ON
            %   	events
            %       TD.ts = event timestamps, typically in units of microseconds
            %
            % 'refracTime'
            %   The refractory period in the same units as 'TD.ts'
            %
            % 'isAccountForPolarity'
            %   A boolean flag indicating whether refraction is applied separately
            %   to each polarity.
            %       isAccountForPolarity = 1 (default) means that refraction is applied
            %                               separately to each polarity
            %       isAccountForPolarity = 0 means that polarity is completely ignored
            %                               by the function when implementing
            %                               refraction
            %
            % written by Garrick Orchard - June 2014
            % garrickorchard@gmail.com
            
            if (numel(evt.x) > evt.actualSize)
                error('Cannot apply refraction if events are not trimmed\n');
            end
            
            if ~exist('isAccountForPolarity', 'var')
                isAccountForPolarity = 1;
            end
            
            indicesToRemove = zeros(length(evt.ts), 1, 'logical');
            
            if isAccountForPolarity
                polarities = unique(evt.p);
                lastTime = cell(length(polarities), 1);
                
                for i = 1:length(polarities)
                    lastTime{i} = ones(evt.width, evt.height) * -refracTime * 2;
                end
                
                for i = 1:length(evt.ts)
                    if (evt.ts(i) - lastTime{evt.p(i)}(evt.x(i), evt.y(i))) > refracTime
                        lastTime{evt.p(i)}(evt.x(i), evt.y(i)) = evt.ts(i);
                    else
                        indicesToRemove(i) = 1;
                    end
                end
            else
                lastTime = ones(evt.width, evt.height) * -refracTime * 2;
                
                for i = 1:length(evt.ts)
                    if (evt.ts(i) - lastTime(evt.x(i), evt.y(i))) > refracTime
                        lastTime(evt.x(i), evt.y(i)) = evt.ts(i);
                    else
                        indicesToRemove(i) = 1;
                    end
                end
            end
            
            evt.remove_events(indicesToRemove);
        end
        
        function tdCopy = clone(evt)
            tdCopy = base_events(evt.width, evt.height);
            tdCopy.x = evt.x;
            tdCopy.y = evt.y;
            tdCopy.ts = evt.ts;
            tdCopy.p = evt.p;
            tdCopy.actualSize = evt.actualSize;
            tdCopy.annotation = evt.annotation;
            tdCopy.comments = evt.comments;
        end
        
        function remove_events(evt, indices)
            % Removes events at the specified indices
            % indices: array of event indices to be removed
            if (numel(evt.x) > evt.actualSize)
                error('Cannot invoke remove_events if events are not trimmed\n');
            elseif numel(indices) ~= evt.actualSize
                error('Mismatch between number of indices and the number of events');
            end
            
            logicalIndices = logical(indices);
            evt.x(logicalIndices) = [];
            evt.y(logicalIndices) = [];
            evt.ts(logicalIndices) = [];
            evt.p(logicalIndices) = [];
            
            evt.actualSize = numel(evt.x);
        end
        
        function [binaryImages, numSpikes] = create_binary_images(evt, durationMicroSec)
            %creates binary images from accumulating spikes over the
            %specified duration
            %
            % returns binary images in a matrix (y, x, , numChannels, imageIndex)
            % numChannels is always 1 for now.
            minTs = min(evt.ts);
            maxTs = max(evt.ts);
            numImages = ceil((maxTs - minTs + 1) / durationMicroSec);
            binaryImages = zeros(evt.height, evt.width, 1, numImages, 'single');
            numSpikes = zeros(1, numImages, 'uint16');
            
            %             for i = 1:numel(binaryImages)
            %                 %retrieve the spikes for the current time period
            %                 startTimeStamp = minTs + ((i-1) * durationMicroSec);
            %                 endTimeStamp = min(startTimeStamp + durationMicroSec, maxTs+1);
            %                 relevantSpikeIndices = find((evt.ts >= startTimeStamp) & (evt.ts < endTimeStamp));
            %
            %                 relevantX = evt.x(relevantSpikeIndices);
            %                 relevantY = evt.y(relevantSpikeIndices);
            %                 %binaryImages{i} = zeros(evt.height, evt.width, 'uint8');
            %                 for j = 1:numel(relevantSpikeIndices)
            %                     binaryImages(relevantY(j), relevantX(j), 1, i) = 1;
            %                     %binaryImages{i}(relevantY(j), relevantX(j)) = 1;
            %                 end
            %             end
            
            tmpTs = evt.ts - minTs + 1;
            imageIndices = ceil(tmpTs / durationMicroSec);
            for i = 1:numel(tmpTs)
                binaryImages(evt.y(i), evt.x(i), 1, imageIndices(i)) = 1;
            end
            
            for i = 1:numImages
                %numSpikes(i) = sum(imageIndices == i);
                numSpikes(i) = sum(sum(binaryImages(:, :, 1, i)));
            end
        end
        
        function binaryImages = create_binary_images_stride(evt, timePeriod, stridePeriod)
            %creates binary images from accumulating spikes over the
            %specified duration, with specified stride period in
            %microseconds
            %
            % returns binary images in a matrix (y, x, , numChannels, imageIndex)
            % numChannels is always 1 for now.
            minTs = min(evt.ts);
            maxTs = max(evt.ts);
            numImages = floor((maxTs - timePeriod) / stridePeriod) + 1;
            binaryImages = zeros(evt.height, evt.width, 1, numImages, 'single');
            
            for i = 1:numImages
                frame = zeros(evt.height, evt.width, 'single');
                %retrieve the spikes for the current time period
                startTimeStamp = minTs + ((i-1) * stridePeriod);
                endTimeStamp = min(startTimeStamp + timePeriod, maxTs+1);
                
                relevantSpikeIndices = find((evt.ts >= startTimeStamp) & (evt.ts < endTimeStamp));
                relevantX = evt.x(relevantSpikeIndices);
                relevantY = evt.y(relevantSpikeIndices);
                for j = 1:numel(relevantSpikeIndices)
                    frame(relevantY(j), relevantX(j)) = 1;
                    %binaryImages{i}(relevantY(j), relevantX(j)) = 1;
                end
                
                binaryImages(:, :, 1, i) = frame;
            end
            
            %             tmpTs = evt.ts - minTs + 1;
            %             imageIndices = ceil(tmpTs / timePeriod);
            %             for i = 1:numel(tmpTs)
            %                 binaryImages(evt.y(i), evt.x(i), 1, imageIndices(i)) = 1;
            %             end
        end
        
        function binaryImages = create_binary_images_spikes(evt, numSpikes, initialOffset, stride)
            %creates binary images from accumulating a specified number of spikes
            % Input
            %   numSpikes - number of spikes to accumulate
            %   initialOffset - number of spikes to skip at the beginning
            %   number of spikes to stride by per image
            
            % Output
            %   returns binary images in a matrix (y, x, , numChannels, imageIndex)
            %   numChannels is always 1 for now.
            numEvts = numel(evt.ts);
            numImages = floor((numEvts - initialOffset - numSpikes) / stride) + 1;
            binaryImages = zeros(evt.height, evt.width, 1, numImages, 'single');
            
            %figure out the start and end indices of events that will form
            %images
            startIndices = initialOffset+1:stride:numEvts-numSpikes+1;
            endIndices = startIndices + numSpikes - 1;
            
            %form the images
            for evtIdx = (initialOffset+1):((numImages-1)*stride + initialOffset + numSpikes)
                imgEndIdx = sum(evtIdx >= startIndices);
                imgStartIdx = sum(evtIdx > endIndices) + 1;
                binaryImages(evt.y(evtIdx), evt.x(evtIdx), 1, imgStartIdx:imgEndIdx) = 1;
            end
        end
        
        function binaryImages = create_binary_images_unique_spikes(evt, numSpikes, startFrameIdx, stride)
            binaryImages = create_binary_images(evt, 1000);
            [~, ~, ~, numFrames] = size(binaryImages);
            numImages = 0;
            
            for i = startFrameIdx:stride:numFrames
                index = i;
                tmpFrame = binaryImages(:, :, 1, index);
                spikeCount = sum(sum(tmpFrame));
                
                while (spikeCount < numSpikes) && (index < numFrames)
                    index = index + 1;
                    tmpFrame = tmpFrame | binaryImages(:, :, 1, index);
                    spikeCount = sum(sum(tmpFrame));
                end
                
                if spikeCount >= numSpikes
                    numImages = numImages + 1;
                    binaryImages(:, :, 1, numImages) = tmpFrame;
                else
                    break;
                end
            end
            
            binaryImages = binaryImages(:, :, :, 1:numImages);
        end
        
        function frames = create_time_surfaces(evt, timePeriod, initialOffset, stridePeriod)
            % initialOffset: initial offset in microseconds
            % timePeriod: num of microseconds per frame
            % stridePeriod: num of microsecond to stride for each frame
            % creates time surfaces in a matrix (column, row, numChannels, imageIndex)
            % numChannels is always 1 for now.
            % each pixel location contains age of the oldest spike (in
            % microseconds)
            
            tmpTs = evt.ts - min(evt.ts) + 1 - initialOffset;
            validRange = tmpTs > 0;
            tmpTs = tmpTs(validRange);
            tmpX = evt.x(validRange);
            tmpY = evt.y(validRange);
            
            maxTs = max(tmpTs);
            numImages = floor((maxTs - timePeriod) / stridePeriod) + 1;
            frames = zeros(evt.height, evt.width, 1, numImages, 'single');
            
            %form the frames
            for i = 1:numImages
                startTime = ((i-1) * stridePeriod + 1);
                endTime = startTime + timePeriod - 1;
                validIndices = tmpTs >= startTime & tmpTs <= endTime;
                timestamps = tmpTs(validIndices);
                microsecondsFromEndTime = (endTime - timestamps + 1);
                xValues = tmpX(validIndices);
                yValues = tmpY(validIndices);
                
                for j = numel(microsecondsFromEndTime):-1:1
                    frames(yValues(j), xValues(j), 1, i) = microsecondsFromEndTime(j);
                end
            end
            
            %             tmpTs = evt.ts - min(evt.ts) + 1 - initialOffset;
            %             validRange = tmpTs > 0;
            %             tmpTs = tmpTs(validRange);
            %             tmpX = evt.x(validRange);
            %             tmpY = evt.y(validRange);
            %
            %             maxTs = max(tmpTs);
            %             numImages = floor((maxTs - timePeriod) / stridePeriod) + 1;
            %             frames = ones(evt.height, evt.width, 1, numImages, 'single');
            %
            %             %form the frames
            %             for i = 1:numImages
            %                 startTime = ((i-1) * stridePeriod + 1);
            %                 endTime = startTime + timePeriod - 1;
            %                 validIndices = tmpTs >= startTime & tmpTs <= endTime;
            %                 timestamps = tmpTs(validIndices);
            %                 microsecondsFromEndTime = 1 - ((endTime - timestamps + 1) / timePeriod);
            %                 xValues = tmpX(validIndices);
            %                 yValues = tmpY(validIndices);
            %
            %                 for j = numel(microsecondsFromEndTime):-1:1
            %                     frames(yValues(j), xValues(j), 1, i) = microsecondsFromEndTime(j);
            %                 end
            %             end
        end
        
        function frames = create_time_evt_count(evt, timePeriod, initialOffset, stridePeriod)
            % initialOffset: initial offset in microseconds
            % timePeriod: num of microseconds per frame
            % stridePeriod: num of microsecond to stride for each frame
            % creates time surfaces in a matrix (column, row, numChannels, imageIndex)
            % numChannels is always 1 for now.
            
            tmpTs = evt.ts - min(evt.ts) + 1 - initialOffset;
            validRange = tmpTs > 0;
            tmpTs = tmpTs(validRange);
            tmpX = evt.x(validRange);
            tmpY = evt.y(validRange);
            
            maxTs = max(tmpTs);
            numImages = floor((maxTs - timePeriod) / stridePeriod) + 1;
            frames = zeros(evt.height, evt.width, 1, numImages, 'single');
            
            %form the frames
            for i = 1:numImages
                startTime = ((i-1) * stridePeriod + 1);
                endTime = startTime + timePeriod - 1;
                tmpFrame = zeros(evt.height, evt.width, 'single');
                combinedFrame = tmpFrame;
                for j = startTime:1000:endTime
                    tmpFrame(:, :, :, :) = 0;
                    endTickTime = min(j+1000, endTime);
                    validIndices = find(tmpTs >= j & tmpTs < endTickTime);
                    xValues = tmpX(validIndices);
                    yValues = tmpY(validIndices);
                    
                    for k=1:numel(validIndices)
                        tmpFrame(yValues(k), xValues(k)) = 1;
                    end
                    combinedFrame = combinedFrame + tmpFrame;
                end
                
                frames(:, :, 1, i) = combinedFrame;
            end
        end
        
        function translate_time(evt, newStartTime)
            minTs = min(evt.ts);
            evt.ts = evt.ts - minTs + newStartTime;
            if ~isempty(evt.annotation)
                evt.annotation.translate_time(-minTs + newStartTime);
            end
        end
        
        function speedup(evt, speedUpFactor)
            minTs = min(evt.ts);
            evt.ts = floor((evt.ts - minTs)/ speedUpFactor) + minTs;
        end
        
        function vid = show(td, timePerFrame, frameLength, startTime, stopTime)
            %   Shows a video of Temporal Difference (TD) events and returns a video
            %   object which can be saved to AVI using the 'SaveMovie' function.
            %   All arguments except TD are optional.
            %   'timePerFrame'
            %       Time Per Frame (TPF) is an optional argument specifying the
            %       time-spacing between the start of subsequent frames (basically the
            %       frame rate for the video). Defaults to 24FPS, which is a Time Per
            %       Frame (TPF) of 1/24 seconds.
            %
            %   'frameLength'
            %       Frame Length (FL) is an optional arguments specifying the time-span
            %       of data to show per frame as a fraction of TPF. Defaults to TPF seconds. If FL<1,
            %       then not all data in a sequence will be shown. If FL>1 then some
            %       data will be repeated in subsequent frames.
            %
            %   'startTime' and 'stopTime'
            %       Optional arguments specifying at which point in time the playback
            %       should start (Tstart) and stop (Tstop). If time_span is not
            %       specified, the entire recording will be shown by default.
            close all;
            
            %TD.p = round(TD.p - min(TD.p) + 1);
            
            %FPS is 1/TPF
            if exist('timePerFrame', 'var')
                fps = 1/timePerFrame;
            else
                fps = 24;
            end
            
            %Frame Length is overlap
            if exist('frameLength', 'var')
                overlap = frameLength;
            else
                overlap = 1;
            end
            
            if exist('startTime', 'var')
                if (startTime == -1)
                    tMin = 1;
                else
                    tMin = find(td.ts > startTime, 1);
                end
            else
                tMin = 1;
            end
            
            if exist('stopTime', 'var')
                if (stopTime == -1)
                    tMax = length(td.ts);
                else
                    tMax = find(td.ts <= stopTime, 1, 'last');
                end
            else
                tMax = length(td.ts);
            end
            
            frameLength = 1/(fps * ndataset_events.TimeConst);
            t1 = td.ts(tMin) + frameLength;
            t2 = td.ts(tMin) + frameLength * overlap;
            
            imageBack = zeros(td.height,td.width,3);
            
            axis image
            i = tMin;
            cc = hsv(single(max(td.p)));
            image = imageBack;
            k=1;
            nFrames = ceil((td.ts(tMax)-td.ts(tMin))/frameLength);
            vid(1:nFrames) = struct('cdata', imageBack, 'colormap', []);
            while (i<tMax)
                j=i;
                while ((td.ts(j) < t2) && (j<tMax))
                    image(td.y(j), td.x(j), :) = cc(td.p(j),:);
                    j = j+1;
                end
                while ((td.ts(i) < t1) && (i<tMax))
                    i = i+1;
                end
                %imshow(image, 'InitialMagnification', 'fit');
                imshow(image, 'InitialMagnification', 100);
                title(sprintf('%03.3fms', td.ts(i) / 1000));
                axis off
                drawnow();
                
                t2 = t1 + frameLength*overlap;
                t1 = t1 + frameLength;
                vid(k).cdata = image;
                image = imageBack;
                k=k+1;
            end
        end
        
        function frames = show_grayscale(td, frameDuration, isDisplay, saveFileName)
            %frameDuration microseconds of data to use in each frame
            close all;
            
            numFrames = ceil((td.ts(end) - td.ts(1) + 1) / frameDuration);
            frames = ones(td.height, td.width, 1, numFrames, 'uint8') * 127;
            tempTs = td.ts - td.ts(1) + 1;
            frameIdx = ceil(tempTs / frameDuration);
            colours = zeros(numel(td.ts), 1, 'uint8');
            colours(td.p == 1) = 255;
            
            for i = 1:numel(tempTs)
                frames(td.y(i), td.x(i), 1, frameIdx(i)) = colours(i);
            end
            
            if exist('saveFileName', 'var')
                writerObj = VideoWriter(saveFileName, 'Grayscale AVI');
                writerObj.FrameRate = 30;
                open(writerObj);
                writeVideo(writerObj, frames);
                close(writerObj);
            end
            
            if (isDisplay)
                for i = 1:numFrames
                    imshow(frames(:, :, :, i), 'InitialMagnification', 300);
                    title(sprintf('%03.3fms', i*frameDuration / 1000));
                    axis off
                    drawnow();
                end
            end
        end
        
        function [track, msFrames] = extract_track(evt, trackNum, xBuffer, yBuffer)
            % creates 1) a new td that contains only the events from  the tracker number
            % 2) 1ms frames of the annotated events. Each frame may be a
            % different size
            tgtAnnotation = evt.annotation.extract_track(trackNum);
            if ~isempty(tgtAnnotation)
                track = evt.clone();
                track.extract_time(tgtAnnotation.ts(1), tgtAnnotation.ts(end)+1);
                track.width = max(tgtAnnotation.xSize) + 2 * xBuffer;
                track.height = max(tgtAnnotation.ySize) + 2 * yBuffer;
                
                %split into 1ms frames
                minTs = min(track.ts);
                maxTs = max(track.ts);
                numImages = ceil((maxTs - minTs + 1) / 1000);
                msFrames = cell(1, numImages);
                eventIdx = 1;
                isOutsideAnnotationBoundary = ones(1, numel(track.ts), 'logical'); %will be used to remove events outside the boundary
                
                for i = 1:numImages
                    endImageTs = double(minTs + i * 1000);
                    endAnnotationIdx = find(tgtAnnotation.ts > endImageTs, 1, 'first');
                    if isempty(endAnnotationIdx)
                        endAnnotationTs = tgtAnnotation.ts(end);
                        endAnnotationPosX = tgtAnnotation.x(end); % centre of annotation
                        endAnnotationPosY = tgtAnnotation.y(end); % centre of annotation
                        endAnnotationSizeX = tgtAnnotation.xSize(end); % size of annotation
                        endAnnotationSizeY = tgtAnnotation.ySize(end); % size of annotation
                    else
                        endAnnotationTs = tgtAnnotation.ts(endAnnotationIdx);
                        endAnnotationPosX = tgtAnnotation.x(endAnnotationIdx); % centre of annotation
                        endAnnotationPosY = tgtAnnotation.y(endAnnotationIdx); % centre of annotation
                        endAnnotationSizeX = tgtAnnotation.xSize(endAnnotationIdx); % size of annotation
                        endAnnotationSizeY = tgtAnnotation.ySize(endAnnotationIdx); % size of annotation
                    end
                    
                    startImageTs = endImageTs - 1000;
                    startAnnotationIdx = find(tgtAnnotation.ts <= startImageTs, 1, 'last');
                    startAnnotationTs = tgtAnnotation.ts(startAnnotationIdx);
                    startAnnotationPosX = tgtAnnotation.x(startAnnotationIdx); % centre of annotation
                    startAnnotationPosY = tgtAnnotation.y(startAnnotationIdx); % centre of annotation
                    startAnnotationSizeX = tgtAnnotation.xSize(startAnnotationIdx); % size of annotation
                    startAnnotationSizeY = tgtAnnotation.ySize(startAnnotationIdx); % size of annotation
                    
                    timeFactor = (endImageTs - startAnnotationTs) / (endAnnotationTs - startAnnotationTs);
                    posX = startAnnotationPosX +  timeFactor*(endAnnotationPosX-startAnnotationPosX); % centre of annotation
                    posY = startAnnotationPosY +  timeFactor*(endAnnotationPosY-startAnnotationPosY); % centre of annotation
                    thresholdX = (startAnnotationSizeX + timeFactor*(endAnnotationSizeX-startAnnotationSizeX)) / 2 + xBuffer; % half size of annotation
                    thresholdY = (startAnnotationSizeY + timeFactor*(endAnnotationSizeY-startAnnotationSizeY)) / 2 + yBuffer; % half size of annotation
                    
                    % generate the 1ms frame
                    frameHeight = ceil(thresholdY * 2);
                    frameWidth = ceil(thresholdX * 2);
                    frame = zeros(frameHeight, frameWidth, 'single');
                    while eventIdx <= numel(track.ts) && track.ts(eventIdx) < endImageTs
                        relativeX = track.x(eventIdx) - posX;
                        relativeY = track.y(eventIdx) - posY;
                        if abs(relativeX) < thresholdX && abs(relativeY) < thresholdY
                            translatedY = round(relativeY + thresholdY);
                            translatedX = round(relativeX + thresholdX);
                            if (translatedY > 0) && (translatedX > 0) && (translatedY <= frameHeight) && (translatedX <= frameWidth)
                                frame(translatedY, translatedX) = 1;
                                isOutsideAnnotationBoundary(eventIdx) = 0;
                            end
                        end
                        
                        eventIdx = eventIdx + 1;
                    end
                    
                    msFrames{i} = frame;
                end
                
                track.x(isOutsideAnnotationBoundary) = [];
                track.y(isOutsideAnnotationBoundary) = [];
                track.ts(isOutsideAnnotationBoundary) = [];
                track.p(isOutsideAnnotationBoundary) = [];
                track.actualSize = numel(track.x);
            else
                track = 0;
                msFrames = 0;
            end
        end
        
        function [track, msFrames] = extract_fixed_size_track(evt, trackNum, width, height, isNormalize)
            % creates 1) a new td that contains only the events from  the tracker number
            % 2) 1ms frames of the annotated events. Each frame may be a
            % different size
            tgtAnnotation = evt.annotation.extract_track(trackNum);
            if ~isempty(tgtAnnotation)
                track = evt.clone();
                track.extract_time(tgtAnnotation.ts(1), tgtAnnotation.ts(end)+1);
                thresholdX = width / 2;
                thresholdY = height / 2;
                
                %split into 1ms frames
                minTs = min(track.ts);
                maxTs = max(track.ts);
                numImages = ceil((maxTs - minTs + 1) / 1000);
                msFrames = cell(1, numImages);
                eventIdx = 1;
                isOutsideAnnotationBoundary = ones(1, numel(track.ts), 'logical'); %will be used to remove events outside the boundary
                
                for i = 1:numImages
                    endImageTs = double(minTs + i * 1000);
                    endAnnotationIdx = find(tgtAnnotation.ts > endImageTs, 1, 'first');
                    if isempty(endAnnotationIdx)
                        endAnnotationTs = tgtAnnotation.ts(end);
                        endAnnotationPosX = tgtAnnotation.x(end); % centre of annotation
                        endAnnotationPosY = tgtAnnotation.y(end); % centre of annotation
                    else
                        endAnnotationTs = tgtAnnotation.ts(endAnnotationIdx);
                        endAnnotationPosX = tgtAnnotation.x(endAnnotationIdx); % centre of annotation
                        endAnnotationPosY = tgtAnnotation.y(endAnnotationIdx); % centre of annotation
                    end
                                        
                    startImageTs = endImageTs - 1000;
                    startAnnotationIdx = find(tgtAnnotation.ts <= startImageTs, 1, 'last');
                    startAnnotationTs = tgtAnnotation.ts(startAnnotationIdx);
                    startAnnotationPosX = tgtAnnotation.x(startAnnotationIdx); % centre of annotation
                    startAnnotationPosY = tgtAnnotation.y(startAnnotationIdx); % centre of annotation
                    
                    timeFactor = (endImageTs - startAnnotationTs) / (endAnnotationTs - startAnnotationTs);
                    posX = startAnnotationPosX +  timeFactor*(endAnnotationPosX-startAnnotationPosX); % centre of annotation
                    posY = startAnnotationPosY +  timeFactor*(endAnnotationPosY-startAnnotationPosY); % centre of annotation
                    
                    % generate the 1ms frame
                    frameHeight = ceil(thresholdY * 2);
                    frameWidth = ceil(thresholdX * 2);
                    frame = zeros(frameHeight, frameWidth, 'single');
                    while eventIdx <= numel(track.ts) && track.ts(eventIdx) < endImageTs
                        relativeX = track.x(eventIdx) - posX;
                        relativeY = track.y(eventIdx) - posY;
                        if abs(relativeX) < thresholdX && abs(relativeY) < thresholdY
                            translatedY = round(relativeY + thresholdY);
                            translatedX = round(relativeX + thresholdX);
                            if (translatedY > 0) && (translatedX > 0) && (translatedY <= frameHeight) && (translatedX <= frameWidth)
                                frame(translatedY, translatedX) = 1;
                                
                                if isNormalize
                                    track.x(eventIdx) = translatedX;
                                    track.y(eventIdx) = translatedY;
                                end
                                isOutsideAnnotationBoundary(eventIdx) = 0;
                            end
                        end
                        
                        eventIdx = eventIdx + 1;
                    end
                    
                    msFrames{i} = frame;
                end
                
                track.x(isOutsideAnnotationBoundary) = [];
                track.y(isOutsideAnnotationBoundary) = [];
                track.ts(isOutsideAnnotationBoundary) = [];
                track.p(isOutsideAnnotationBoundary) = [];
                track.actualSize = numel(track.x);
                track.annotation = tgtAnnotation;
                
                if isNormalize
                    track.width = width;
                    track.height = height;
                end
                
                if track.actualSize == 0
                    track = [];
                    msFrames = [];
                end
            else
                track = [];
                msFrames = [];
            end
        end
        
        function extract_time(evt, startTimeUs, endTimeUs)
            % extract_time(top, startTimeUs, endTimeUs, isNormalize)
            %   Extracts a temporal Region Of Interest (ROI) from the events
            %
            % TAKES IN:
            % 'startTimeUs' and 'endTimeUs'
            %       The absolute start and end times in microseconds.
            
            indices = evt.ts >= startTimeUs & evt.ts < endTimeUs;
            evt.x = evt.x(indices);
            evt.y = evt.y(indices);
            evt.p = evt.p(indices);
            evt.ts = evt.ts(indices);
            evt.actualSize = numel(evt.ts);
        end
        
        function write_linux(evt, filename)
            %             if ~exist('eventsPerPacket', 'var')
            %                 eventsPerPacket = 2048; %default to 2048 events per packet
            %             end
            
            %open the file
            outputFile = fopen(filename, 'w');
            
            %write a short header
            fprintf(outputFile, 'v2\n');
            if isempty(evt.comments)
                fprintf(outputFile, '#Event file for linux_aer created using Matlab function "write_linux" at time %s\n', datestr(now));
            else
                fixedComments = evt.comments;
                while strcmp(fixedComments(end), '\n')
                    fixedComments(end) = [];
                end
                
                fprintf(outputFile, strcat(fixedComments, '\n'));
            end
            %write the resolution of these events, followed by a newline
            fwrite(outputFile, [evt.width, evt.height], 'uint16');
            %fwrite(outputFile, evt.height, 'uint32');
            fprintf(outputFile, '\n');
            
            %             numOverflows = floor(evt.ts(end)/(2^16));
            %
            %             overflowEvents.x       = zeros(1,numOverflows);
            %             overflowEvents.y       = zeros(1,numOverflows);
            %             overflowEvents.type    = 2*ones(1,numOverflows);
            %             overflowEvents.subtype = zeros(1,numOverflows);
            %             overflowEvents.ts      = (1:numOverflows)*(2^16)-0.5;
            %
            writeEvents.x = double(evt.x-1);
            writeEvents.y = double(evt.y-1);
            writeEvents.type = zeros(1,length(evt.ts));
            writeEvents.subtype = evt.p;
            writeEvents.ts = evt.ts;
            
            %             writeEvents = CombineStreams(writeEvents, overflowEvents);
            writeEvents.ts = ceil(writeEvents.ts);
            
            %             if length(writeEvents.ts) ~= length(evt.ts) + numOverflows
            %                 disp('error in calculating the number of overflow events')
            %             end
            numEventsRemaining = length(writeEvents.ts);
            %write_events.ts = rem(write_events.ts, 2^16);
            
            eventIdx = 1;
            while numEventsRemaining >0
                startTime = bitshift(writeEvents.ts(eventIdx), -16);
                endTime = startTime+1;
                startTimeUs = bitshift(startTime, 16);
                endTimeUs = bitshift(endTime, 16);
                endIdx = find(writeEvents.ts < endTimeUs, 1, 'last');
                num_events = endIdx - eventIdx + 1;
                %                 num_events = min(eventsPerPacket, numEventsRemaining);
                fwrite(outputFile, num_events, 'uint32');
                fwrite(outputFile, startTime, 'uint32');
                fwrite(outputFile, endTime, 'uint32');
                
                writeEvents.ts(eventIdx:endIdx) = writeEvents.ts(eventIdx:endIdx) - startTimeUs;
                
                
                %                 fwrite(outputFile, floor(writeEvents.ts(eventIdx)/2^16)*2^16, 'uint32');
                %                 %    fwrite(output_file, end_time, 'uint32');
                %                 fwrite(outputFile, floor(writeEvents.ts(eventIdx+num_events-1)/2^16)*2^16, 'uint32');
                %                 %fwrite(outputFile, writeEvents.ts(eventIdx), 'uint32');
                %                 %fwrite(outputFile, writeEvents.ts(eventIdx+num_events-1), 'uint32');
                %                 fwrite(outputFile, floor(writeEvents.ts(eventIdx)/2^16)*2^16, 'uint32');
                %                 %    fwrite(output_file, end_time, 'uint32');
                %                 fwrite(outputFile, floor(writeEvents.ts(eventIdx+num_events-1)/2^16)*2^16, 'uint32');
                
                %num_events = bitshift(raw_data_buffer(buffer_location+3), 24) + bitshift(raw_data_buffer(buffer_location+2), 16) + bitshift(raw_data_buffer(buffer_location+1), 8) + raw_data_buffer(buffer_location);
                buffer = zeros(1, 8*num_events);
                buffer(1:8:end) = writeEvents.type(eventIdx:endIdx);
                buffer(2:8:end) = writeEvents.subtype(eventIdx:endIdx);
                buffer(3:8:end) = writeEvents.y(eventIdx:endIdx);
                buffer(5:8:end) = bitand(writeEvents.x(eventIdx:endIdx), 255, 'int32');
                buffer(6:8:end) = bitshift(writeEvents.x(eventIdx:endIdx), -8);
                buffer(7:8:end) = bitand(writeEvents.ts(eventIdx:endIdx), 255, 'int32');
                try
                    buffer(8:8:end) = bitand(bitshift(writeEvents.ts(eventIdx:endIdx), -8), 255, 'uint32');
                catch e
                    rethrow(e);
                end
                
                fwrite(outputFile, buffer, 'uint8');
                
                numEventsRemaining = numEventsRemaining - num_events;
                eventIdx = eventIdx + num_events;
            end
            
            fclose(outputFile);
        end
    end
    
    methods(Access = private)
        
    end
    
end

