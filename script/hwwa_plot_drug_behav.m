function hwwa_plot_drug_behav(rt, labels, varargin)

assert_ispair( rt, labels );

defaults = hwwa.get_common_make_defaults();
params = hwwa.parsestruct( defaults, varargin );

days_5htp = hwwa.get_image_5htp_days();
days_sal = hwwa.get_image_saline_days();

use_days = unique( horzcat(days_5htp, days_sal) );

d = 10;

end