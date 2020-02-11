conf = hwwa.config.load();
behav_outs = hwwa_load_approach_avoid_behavior( 'config', conf );

%%

aligned_outs = hwwa_approach_avoid_fix_on_aligned( 'config', conf );
go_targ_aligned_outs = hwwa_approach_avoid_go_target_on_aligned( 'config', conf );
saccade_outs = hwwa_saccade_info( go_targ_aligned_outs );

%%  Get nogo rt

saccade_based_rt = hwwa.saccade_based_reaction_time( go_targ_aligned_outs, saccade_outs );
target_entry_based_rt = hwwa.target_entry_based_rt( go_targ_aligned_outs );

behav_ids = categorical( behav_outs.labels, {'unified_filename', 'trial_number'} );
aligned_ids = categorical( go_targ_aligned_outs.labels, {'unified_filename', 'trial_number'} );
assert( isequal(behav_ids, aligned_ids) );

nogo_selectors = { 'nogo_trial', 'correct_false' };

nogo_ind = find( behav_outs.labels, nogo_selectors );
go_ind = hwwa.find_correct_go( behav_outs.labels );

%%

rt_kind = 'reaction_time';
adjusted_rt = behav_outs.rt;

switch ( rt_kind )
  case 'reaction_time'
    use_rt = saccade_based_rt;
  case 'response_time'
    use_rt = target_entry_based_rt;
  case 'movement_time'
    use_rt = target_entry_based_rt - saccade_based_rt;
    use_rt(use_rt < 0) = nan;
  otherwise
    error( 'Unrecognized rt kind "%s".', rt_kind );
end

adjusted_rt(nogo_ind) = use_rt(nogo_ind) / 1e3;
adjusted_rt(go_ind) = use_rt(go_ind) / 1e3;

%%

approach_mask = hwwa.get_approach_avoid_mask( behav_outs.labels, go_ind );

missing_saccade_based_rt = isnan( saccade_based_rt(approach_mask) );
missing_orig_rt = behav_outs.rt(approach_mask) == 0;

%%

find_non_outliers = @(labels, varargin) find( labels, 'is_outlier__false', varargin{:} );

n_devs = 2;

pupil_labels = aligned_outs.labels';
pupil_size = nanmean( aligned_outs.pupil, 2 );
mask = find( pupil_labels, 'initiated_true' );

norm_each = { 'unified_filename' };

in_bounds = hwwa.within_std_threshold( pupil_size, pupil_labels, n_devs, norm_each, mask );
hwwa.apply_outlier_labels( pupil_labels, in_bounds, 'unified_filename', behav_outs.labels );
hwwa.apply_outlier_labels( pupil_labels, in_bounds, 'unified_filename', pupil_labels );

%%

% rt = behav_outputs.rt;
rt = adjusted_rt;
use_labs = behav_outs.labels';
hwwa.decompose_social_scrambled( use_labs );
time = behav_outs.run_relative_start_times;

slide_each = { 'unified_filename', 'target_image_category', 'trial_type', 'scrambled_type' };
prop_mask = find_non_outliers( use_labs, hwwa.get_approach_avoid_mask(use_labs) );
win_size = 50;
step_size = 1;

time_window_size = 240;
% time_step_size = 10;
time_step_size = 20;

time_prop_bin_func = @(data, labels, mask) hwwa.single_percent_correct(labels, mask);

[props, prop_labels, bin_inds] = ...
  hwwa.sliding_window_percent_correct( use_labs, slide_each, win_size, step_size, prop_mask );

[time_props, time_prop_edges, time_prop_labels, time_bin_inds] = ...
  hwwa.time_slide_bin_apply( time, time, use_labs', slide_each ...
    , time_window_size, time_step_size, time_prop_bin_func, prop_mask );

time_bin_counts = cellfun( @numel, time_bin_inds );

time_props = cellfun( @nanmedian, time_props );

rt_func = @(rt, labels, inds) nanmedian(rt(inds));
rt_mask = hwwa.find_correct_go_incorrect_nogo( use_labs, prop_mask );

[slide_rt, slide_rt_labels, rt_bin_inds] = ...
  hwwa.sliding_window_summary( rt, use_labs, slide_each, 10, 1, rt_func, rt_mask );

med_inds = cellfun( @median, bin_inds );
start_times = behav_outs.run_relative_start_times(med_inds);

rt_inds = cellfun( @min, rt_bin_inds );
rt_start_times = behav_outs.run_relative_start_times(rt_inds);

%%

% hwwa_plot_sliding_window_behavior( props, start_times, prop_labels', 'slide_window_p_correct' ...
%   , 'do_save', true ...
%   , 'saline_normalize', true ...
% );

slide_window_rt_kind = sprintf( 'slide_window_%s', rt_kind );

hwwa_plot_sliding_window_behavior( slide_rt, rt_start_times, slide_rt_labels', slide_window_rt_kind ...
  , 'do_save', true ...
  , 'saline_normalize', false ...
  , 'per_monkey', false ...
  , 'mask_func', @(varargin) hwwa.find_correct_go(varargin{:}) ...
  , 'line_xlims', [0, 3.3e3] ...
);

%%  p correct over time

hwwa_plot_time_binned_behavior( time_props, time_prop_edges, time_prop_labels ...
  , 'time_limits', [-inf, 3.5e3] ...
  , 'do_save', true ...
  , 'per_monkey', false ...
);

%%  num initiated per session

hwwa_plot_num_initiated_per_session( use_labs' ...
  , 'per_scrambled_type', false ...
  , 'do_save', true ...
);

%%  amp-velocity tradeoff



%%  rt / velocity

is_saccade_vel = true;

if ( is_saccade_vel )
  use_data = nan( rows(pupil_labels), 1 );
  use_data(saccade_outs.aligned_to_saccade_ind) = saccade_outs.saccade_velocities;
  use_labels = pupil_labels';  % with outlier labels
  use_kind = 'saccade_velocity';
else
  use_data = adjusted_rt;
  use_labels = behav_outs.labels';
  use_kind = rt_kind;
end

image_cat_combs = [ true, false ];
per_monk_combs = [ false ];
norm_combs = [ true ];

plt_combs = dsp3.numel_combvec( image_cat_combs, per_monk_combs, norm_combs );

for i = 1:size(plt_combs, 2)
  per_image_cat = image_cat_combs(plt_combs(1, i));
  per_monkey = per_monk_combs(plt_combs(2, i));
  do_norm = norm_combs(plt_combs(3, i));

  hwwa_plot_approach_avoid_behav( use_data, use_labels' ...
    , 'do_save', true ...
    , 'normalize', do_norm ...
    , 'mask_func', find_non_outliers ...
    , 'base_subdir', '' ...
    , 'match_figure_limits', true ...
    , 'per_monkey', per_monkey ...
    , 'per_image_category', per_image_cat ...
    , 'rt_kind', use_kind ...
    , 'y_lims', [0, 2.4] ...
  );
end

%%

hwwa_plot_pupil( pupil_size, pupil_labels ...
  , 'do_save', true ...
  , 'mask_func', find_non_outliers ...
);
