function hwwa_make_approach_avoid_behavioral_data(varargin)

defaults = hwwa.get_common_make_defaults();
params = hwwa.parsestruct( defaults, varargin );

conf = params.config;

behav_outs = hwwa_load_approach_avoid_behavior( 'config', conf );
aligned_outs = hwwa_approach_avoid_fix_on_aligned( 'config', conf );

%%

hwwa_approach_avoid_make_apply_outlier_labels( aligned_outs, behav_outs );

save_p = get_save_p( params );
file_path = fullfile( save_p, get_filename(params) );
shared_utils.io.require_dir( save_p );

save( file_path, 'behav_outs' );

end

function fname = get_filename(params)

fname = 'behav.mat';

end

function save_p = get_save_p(params)

save_p = hwwa.gid( 'processed/behavior', params.config );

end