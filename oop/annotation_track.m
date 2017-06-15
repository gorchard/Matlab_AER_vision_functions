classdef annotation_track < handle
    %ANNOTATION_TRACK Each track has a class and contains an array of
    %points sorted by timestamp

    properties
        class; % integer corresponding to the annotation's class 1 - Car, 2 - Bus, 3 - Van, 4 - Pedestrian, 5 - Bike, 6 - Truck, 7 - Unknown
    end
    
    properties(SetAccess = protected)
        points = annotation_point.empty(); %array of annotation_points
    end
    
    methods
        function track = annotation_track(class)
            track.class = class;
        end
        
        function newPointIdx = add_point(track, point)
            %add a point to this track
            track.points(end+1) = point;
            [~, idx] = sort([track.points.ts]);
            [~, newPointIdx] = max(idx);
            track.points = track.points(idx);
        end
        
        function isSuccess = delete_point(track, idx)
            %remove point (by index) from this track
            isSuccess = 0;
            if idx > 0 && idx <= numel(track.points)
                track.points(idx) = [];
                isSuccess = 1;
            end
        end
        
        function translate_time(track, translation)
            arrayfun(@(x) x.translate_time(translation), track.points);
        end
    end
    
end

