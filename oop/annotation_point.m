classdef annotation_point < handle
    %ANNOTATION_POINT consists of timestamp, centrepoint and size
    
    properties
        x; % x-value of center of annotation box
        y; % y-value of center of annotation box
        xSize; % width of annotation box
        ySize; % height of annotation box
        ts; %time stamp
    end
    
    methods
        function point = annotation_point(x, y ,xSize, ySize, ts)
            point.x = x;
            point.y = y;
            point.xSize = xSize;
            point.ySize = ySize;
            point.ts = ts;
        end
        
        function translate_time(point, translation)
            point.ts = point.ts + translation;
        end
        
        function edit(point, x, y, xSize, ySize)
            point.x = x;
            point.y = y;
            point.xSize = xSize;
            point.ySize = ySize;
        end
    end
    
end

