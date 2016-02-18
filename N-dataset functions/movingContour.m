function obj_contour = movingContour(contour, currentTime)
% obj_contour = movingContour(contour, currentTime)
% Simulates motion of an object contour resulting from sensor saccades.
% This function returns 'obj_contour', which is the location of the object
% contour at the present time, indicated by 'currentTime' (in
% microseconds).
% 'contour' is the initial position of the object contour
% 
% written by Garrick Orchard - July 2015

if currentTime<100e3
    obj_contour(1,:) = contour(1,:) + 3.5*currentTime/100e3;
    obj_contour(2,:) = contour(2,:) + 7*currentTime/100e3;
elseif currentTime<200e3
    obj_contour(1,:) = contour(1,:) + 3.5 + 3.5*(currentTime-100e3)/100e3;
    obj_contour(2,:) = contour(2,:) + 7   - 7*(currentTime-100e3)/100e3;
elseif currentTime<300e3
    obj_contour(1,:) = contour(1,:) + 7   - 7*(currentTime-200e3)/100e3;
    obj_contour(2,:) = contour(2,:);
else
    obj_contour(1,:) = contour(1,:);
    obj_contour(2,:) = contour(2,:);
end
