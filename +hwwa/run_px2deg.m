function [x_deg, y_deg] = run_px2deg(x, y, flip_y)

if ( nargin < 3 )
  flip_y = false;
end

monitor_constants = hwwa.monitor_constants();

h = monitor_constants.monitor_height_cm;
d = monitor_constants.z_dist_to_subject_cm;
r = monitor_constants.vertical_resolution_px;

if ( flip_y )
  y = r - y;
end

x_deg = hwwa.px2deg( x, h, d, r );
y_deg = hwwa.px2deg( y, h, d, r );

end