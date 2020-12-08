conf = hwwa.config.load();
behav_outs = hwwa_load_approach_avoid_behavioral_data( conf );
saccade_outs = hwwa_load_approach_avoid_saccade_info( conf );

%%

cue_on_pup = behav_outs.cue_on_aligned.pupil;
cue_on_t = behav_outs.cue_on_aligned.time;

cue_on_norm_pup = hwwa.time_normalize( cue_on_pup, cue_on_t, [-150, 0] );
cue_on_norm_pup(cue_on_norm_pup == 0) = nan;
cue_on_slice = cue_on_norm_pup(:, cue_on_t >= 0 & cue_on_t <= 800 );
cue_on_max_diff = min( cue_on_slice, [], 2 );


%%

per_rt_quantile = false;
session_level_rt_quantile = true;
num_rt_quantiles = 2;

find_non_outliers = @(labels, varargin) find( labels, 'is_outlier__false', varargin{:} );

use_labs = behav_outs.labels';
hwwa.decompose_social_scrambled( use_labs );
time = behav_outs.run_relative_start_times;

rt = saccade_outs.rt.saccade_based_rt;

slide_each = { 'unified_filename', 'target_image_category', 'trial_type', 'scrambled_type' };

prop_mask = find_non_outliers( use_labs, hwwa.get_approach_avoid_mask(use_labs) );
rt_mask = hwwa.find_correct_go_incorrect_nogo( use_labs, prop_mask );

quant_cat = 'rt-quantile';
make_quant_labs = @(quants) arrayfun(@(x) sprintf('%s__%d', quant_cat, x), quants, 'un', 0);

if ( per_rt_quantile && ~session_level_rt_quantile )
  quants_of = 'unified_filename';
  quants_each = setdiff( slide_each, quants_of );
  [quants, quant_I] = dsp3.quantiles_each( rt, use_labs', num_rt_quantiles ...
    , quants_each, quants_of, rt_mask );
  addsetcat( use_labs, quant_cat, make_quant_labs(quants) );
  slide_each = union( slide_each, {quant_cat} );
end

% Average percent correct + rt per session.
[pcorr, pcorr_labels] = hwwa.percent_correct( use_labs', slide_each, prop_mask );
[mean_rt_labels, mean_rt_I] = keepeach( use_labs', slide_each, rt_mask );
mean_rt = bfw.row_nanmean( rt, mean_rt_I );

if ( per_rt_quantile && session_level_rt_quantile )
  quants_of = 'unified_filename';
  [quants, quant_I] = dsp3.quantiles_each( mean_rt, mean_rt_labels', num_rt_quantiles ...
    , setdiff(slide_each, quants_of), quants_of );
  addsetcat( mean_rt_labels, quant_cat, make_quant_labs(quants) );
  slide_each = union( slide_each, {quant_cat} );
end

%%

base_pup = nanmean( cue_on_pup(:, cue_on_t >= -150 & cue_on_t <= 0), 2 );
inds = findall( use_labs, 'unified_filename' );
quants = bfw.row_nanmedian( base_pup, inds );

set_a = {};
set_b = {};

for i = 1:numel(inds)
  set_a{end+1, 1} = inds{i}(base_pup(inds{i}) < quants(i));
  set_b{end+1, 1} = inds{i}(base_pup(inds{i}) >= quants(i));
end

pre = vertcat( set_a{:} );
post = vertcat( set_b{:} );

ax = subplot( 1, 2, 1 );
hist( ax, cue_on_max_diff(pre), 1e3 );

ax2 = subplot( 1, 2, 2 );
hist( ax2, cue_on_max_diff(post), 1e3 );

%%

time_window_size = 240;
time_step_size = 20;

time_prop_bin_func = @(data, labels, mask) hwwa.single_percent_correct(labels, mask);

[time_props, time_prop_edges, time_prop_labels, time_bin_inds] = ...
  hwwa.time_slide_bin_apply( time, time, use_labs', slide_each ...
    , time_window_size, time_step_size, time_prop_bin_func, prop_mask );

% Sliding window rt
rt_func = @(rt, labels, inds) nanmedian( rt );
  
[time_rt, time_rt_edges, time_rt_labels, time_rt_bin_inds] = ...
  hwwa.time_slide_bin_apply( rt, time, use_labs', slide_each ...
    , time_window_size, time_step_size, rt_func, rt_mask );
  
time_props = cellfun( @nanmedian, time_props ); 
time_rt = cellfun( @nanmedian, time_rt );

%%  quantiles x percent correct y

for_quant_type = 'max_pup_diff';

switch ( for_quant_type )
  case 'max_pup_diff'
    for_quant = cue_on_max_diff;
  case 'rt'
    for_quant = rt;
  case 'base_pupil_size'
    for_quant = behav_outs.pupil_size;
  otherwise
    error( 'Unhandled for quant type.' );
end

find_non_nan = @(l, m, x) intersect(find_non_outliers(l, m), find(~isnan(x)));
find_non_nan_quant = @(l, m) find_non_nan(l, m, for_quant);

for_quant_labels = use_labs';
% for_quant_each = union( slide_each, {'unified_filename'} );
for_quant_each = { 'unified_filename' };
for_quant_of = {};
for_quant_mask = hwwa.get_approach_avoid_base_mask( for_quant_labels, find_non_nan_quant );
num_quants = 20;

% [quant_pcorr, quant_pcorr_labels, quant_match_inds] = ...
%   hwwa.quantiles_x_percent_correct_y( for_quant, for_quant_labels ...
%   , for_quant_each, for_quant_of, num_quants, for_quant_mask );
% quant_x = bfw.row_nanmean( for_quant, quant_match_inds );

[quants, each_I] = dsp3.quantiles_each( for_quant, for_quant_labels, num_quants ...
  , for_quant_each, for_quant_of, for_quant_mask );
dsp3.add_quantile_labels( for_quant_labels, quants, 'x-quantile' );

[quant_pcorr, quant_pcorr_labels] = ...
  hwwa.percent_correct( for_quant_labels', union(slide_each, 'x-quantile'), for_quant_mask );
quant_x = nan( size(quant_pcorr) );

%%

per_sts = trufls;
per_tts = trufls;
cs = dsp3.numel_combvec( per_sts, per_tts );

for i = 1:size(cs, 2)
  c = cs(:, i);

  mask_func = find_non_outliers;

  hwwa_relate_quantiles_x_percent_correct_y( quant_x, quant_pcorr, quant_pcorr_labels' ...
    , 'mask_func', mask_func ...
    , 'do_save', true ...
    , 'per_scrambled_type', per_sts(c(1)) ...
    , 'per_trial_type', per_tts(c(2)) ...
    , 'x_label', for_quant_type ...
    , 'quantile_index_x', true ...
    , 'x_lims', [0, 21] ...
    , 'permutation_test', true ...
  );
end

%%  binned baseline pupil vs. p-correct

per_sts = false;
per_tts = true;
per_monks = true;

num_pup_quantiles = 20;

mask_func = find_non_outliers;
cs = dsp3.numel_combvec( per_sts, per_tts, per_monks );

for i = 1:size(cs, 2)
  shared_utils.general.progress( i, size(cs, 2) );
  c = cs(:, i);
  
  hwwa_baseline_pupil_quantile_vs_p_correct( behav_outs.pupil_size, use_labs' ...
    , 'mask_func', mask_func ...
    , 'per_scrambled_type', per_sts(c(1)) ...
    , 'per_trial_type', per_tts(c(2)) ...
    , 'per_monkey', per_monks(c(3)) ...
    , 'do_save', true ...
    , 'permutation_test', true ...
    , 'permutation_test_iters', 1e2 ...
    , 'num_quantiles', num_pup_quantiles ...
    , 'y_lims', [0.1, 1] ...
  );
end

%%  pupil vs num initiated

labels = use_labs';

per_sts = trufls;
per_tts = trufls;
per_monks = trufls;
metric_names = { 'baseline', 'max_diff' };

mask_func = find_non_outliers;
cs = dsp3.numel_combvec( per_sts, per_tts, per_monks, metric_names );

for i = 1:size(cs, 2)
  c = cs(:, i);
  
  pupil_metric_name = metric_names{c(4)};

  pupil_metric = ternary( strcmp(pupil_metric_name, 'baseline') ...
    , behav_outs.pupil_size, cue_on_max_diff ...
  );
  
  hwwa_relate_num_initiated_to_pupil( pupil_metric, labels ...
    , 'mask_func', mask_func ...
    , 'per_scrambled_type', per_sts(c(1)) ...
    , 'per_trial_type', per_tts(c(2)) ...
    , 'per_monkey', per_monks(c(3)) ...
    , 'pupil_metric', pupil_metric_name ...
    , 'permutation_test', true ...
    , 'do_save', true ...
  );
end

%%  overall p correct

mask_func = find_non_outliers;
% mask_func = @hwwa.default_mask_func;

hwwa_overall_p_correct( use_labs' ...
  , 'mask_func', mask_func ...
  , 'do_save', true ...
  , 'anova_factors', {'trial_type', 'scrambled_type', 'target_image_category'} ...
  , 'per_drug', false ...
  , 'per_target_image_category', true ...
);

%%  overall pupil size

hwwa_overall_pupil_size( behav_outs.pupil_size, use_labs' ...
  , 'mask_func', find_non_outliers ...
  , 'do_save', true ...
  , 'per_monkey', false ...
  , 'per_scrambled_type', false ...
  , 'per_trial_type', false ...
  , 'per_correct', false ...
  , 'normalize', true ...
  , 'add_points', true ...
  , 'points_are', 'monkey' ...
  , 'run_level_average', true ...
  , 'signrank_inputs', {1} ... % test against 1.
);

%%  overall rt

mask_func = find_non_outliers;

per_cats = false;
per_monks = false;
% per_scrambled_types = true;
per_scrambled_types = false;
% norms = trufls;
norms = false;
% trial_levels = trufls;
trial_levels = false;
per_image_cats = false;

cs = dsp3.numel_combvec( per_cats, per_monks, per_scrambled_types, norms ...
  , trial_levels, per_image_cats );

for i = 1:size(cs, 2)
  
per_cat = per_cats(cs(1, i));
per_monk = per_monks(cs(2, i));
per_scrambled_type = per_scrambled_types(cs(3, i));
do_norm = norms(cs(4, i));
trial_level = trial_levels(cs(5, i));
per_image_cat = per_image_cats(cs(6, i));

norm_lims = {[], []};
non_norm_lims = {[0, 0.4], [0.1, 0.3]};

lims = ternary( do_norm, norm_lims, non_norm_lims );

if ( trial_level )
  y_lims = lims{1};
else
  y_lims = lims{2};
end

hwwa_overall_rt( rt, use_labs' ...
  , 'mask_func', mask_func ...
  , 'do_save', true ...
  , 'per_image_category', per_cat ...
  , 'per_monkey', per_monk ...
  , 'per_scrambled_type', per_scrambled_type ...
  , 'per_image_category', per_image_cat ...
  , 'include_nogo', true ...
  , 'trial_level', trial_level ...
  , 'normalize', do_norm ...
  , 'add_points', true ...
  , 'points_are', 'monkey' ...
  , 'y_lims', y_lims ...
);

end

%%  p correct vs. rt

hwwa_scatter_rt_p_correct_over_time( ...
  pcorr, pcorr_labels', mean_rt, mean_rt_labels', slide_each ...
  , 'permutation_test', false ...
  , 'permutation_test_iters', 1e2 ...
  , 'do_save', true ...
  , 'per_monkey', false ...
  , 'per_rt_quantile', true ...
  , 'mask_func', @(l, m) findnone(l, 'rt-quantile__NaN') ...
  , 'remove_outliers', false ...
  , 'std_threshold', 2 ...
  , 'order_each_func', @(slide_each) setdiff(slide_each, 'rt-quantile') ...
  , 'x_lims', [0.14, 0.3] ...
  , 'y_lims', [0, 1.2] ...
  , 'anova_each', {} ...
  , 'normalize_pcorr', true ...
);

%%  p correct vs. rt over time

hwwa_scatter_rt_p_correct_over_time( ...
  time_props, time_prop_labels, time_rt, time_rt_labels, slide_each ...
);

%%  p correct or rt over time

use_rt_for_over_time = true;

if ( use_rt_for_over_time )
  use_props = time_rt;
  use_prop_edges = time_rt_edges;
  use_prop_labels = time_rt_labels';
  over_time_prefix = 'rt--';
else
  use_props = time_props;
  use_prop_edges = time_prop_edges;
  use_prop_labels = time_prop_labels';
  over_time_prefix = 'pcorr--';
end

hwwa_plot_time_binned_behavior( use_props, use_prop_edges, use_prop_labels' ...
  , 'time_limits', [-inf, 3.5e3] ...
  , 'do_save', true ...
  , 'per_monkey', false ...
  , 'per_drug', true ...
  , 'prefix', over_time_prefix ...
);

%%  num initiated per session

% per_scrambled_types = trufls();
per_scrambled_types = false;
% per_drugs = trufls();
per_drugs = true;
% per_trial_types = trufls();
per_trial_types = false;
cs = dsp3.numel_combvec( per_scrambled_types, per_drugs, per_trial_types );

for i = 1:size(cs, 2)
  
shared_utils.general.progress( i, size(cs, 2) );
  
c = cs(:, i);

hwwa_plot_num_initiated_per_session( use_labs' ...
  , 'per_scrambled_type', per_scrambled_types(c(1)) ...
  , 'per_drug', per_drugs(c(2)) ...
  , 'per_trial_type', per_trial_types(c(3)) ...
  , 'do_save', true ...
  , 'mask_func', find_non_outliers ...
  , 'permutation_test', false ...
  , 'compare_drug', true ...
);

end

%%  p correct vs num initiated next

per_scrambled_types = trufls();
per_drugs = true;
per_trial_types = trufls();
cs = dsp3.numel_combvec( per_scrambled_types, per_drugs, per_trial_types );

for i = 1:size(cs, 2)
  
shared_utils.general.progress( i, size(cs, 2) );
  
c = cs(:, i);

hwwa_plot_n_plus_one_performance( use_labs' ...
  , 'per_scrambled_type', per_scrambled_types(c(1)) ...
  , 'per_drug', per_drugs(c(2)) ...
  , 'per_trial_type', per_trial_types(c(3)) ...
  , 'do_save', true ...
  , 'mask_func', find_non_outliers ...
);

end

%%  amp-velocity tradeoff

vel = nan( rows(use_labs), 1 );
amp = nan( size(vel) );

to_sacc_ind = saccade_outs.aligned_to_saccade_ind;

vel(to_sacc_ind) = saccade_outs.saccade_peak_velocities;
amp(to_sacc_ind) = saccade_outs.saccade_lengths;

hwwa_plot_amp_vel_tradeoff( amp, vel, use_labs' ...
  , 'mask_func', find_non_outliers ...
  , 'per_monkey', true ...
  , 'do_save', true ...
  , 'permutation_test', true ...
  , 'permutation_test_iters', 1e2 ...
  , 'base_subdir', 'social_v_scrambled' ...
);

%%  relate pupil size with rt, saccade, velocity, amplitude

% types = { 'amp', 'vel', 'rt' };
% types = { 'vel' };
types = { 'pupil_max_diff' };
per_monks = [false];
per_scrambled_types = [true];
cs = dsp3.numel_combvec( types, per_monks, per_scrambled_types );

use_pupil_size = behav_outs.pupil_size;
% use_pupil_size = cue_on_max_diff;

for i = 1:size(cs, 2)
  
second_measure_type = types{cs(1, i)};
per_monk = per_monks(cs(2, i));
per_scrambled_type = per_scrambled_types(cs(3, i));

switch ( second_measure_type )
  case 'rt'
    second_measure = rt;
  case 'vel'
    second_measure = vel;
  case 'amp'
    second_measure = amp;
  case 'pupil_max_diff'
    second_measure = cue_on_max_diff;
  otherwise
    error( 'Unrecognized second measure type "%s".', second_measure_type );
end

mask_func = ...
  @(l, m) hwwa.find_correct_go_incorrect_nogo(l, find_non_outliers(l, m));

hwwa_relate_to_pupil_size( use_pupil_size, second_measure, use_labs' ...
  , 'second_measure_name', second_measure_type ...
  , 'mask_func', mask_func ...
  , 'do_save', true ...
  , 'per_monkey', per_monk ...
  , 'per_scrambled_type', per_scrambled_type ...
  , 'permutation_test', true ...
  , 'remove_x_outliers', false ...
  , 'outlier_std_thresh', 2 ...
);

end

%%  Pupil traces

pup_labs = use_labs';

use_quantiles = false;

use_aligned_outs = behav_outs.cue_on_aligned;
use_aligned_outs.labels = pup_labs;

quantile_measure = rt;
quantile_measure(quantile_measure == 0) = nan;

num_tiles = 3;
quant_cat = 'rt-quantile';
quant_each = { 'unified_filename', 'trial_type' };
quant_mask_func = @(l, m) fcat.mask(l, find_non_outliers(l, m) ...
  , @(l, arg, m) intersect(arg, m), find(~isnan(quantile_measure)) ...
);
quant_mask_func = @(l, m) ...
  hwwa.find_correct_go_incorrect_nogo(l, quant_mask_func(l, m));

quant_mask = hwwa.get_approach_avoid_base_mask( pup_labs, quant_mask_func );

quant_inds = dsp3.quantiles_each( quantile_measure, pup_labs' ...
  , num_tiles, quant_each, {}, quant_mask );
quant_labs = arrayfun( @(x) sprintf('%s-%d', quant_cat, x), quant_inds, 'un', 0 );
addsetcat( pup_labs, quant_cat, quant_labs );

thresh = 0;
require_crit = false;

if ( use_quantiles )
  wrap_mask_func = @(l, m) fcat.mask(l, find_non_outliers(l, m) ...
    , @findnone, 'rt-quantile-NaN' ...
  );
  pupil_fcats = quant_cat;
else
  wrap_mask_func = find_non_outliers;
  pupil_fcats = {};
end

prefix = ternary( require_crit, sprintf('crit-%d', thresh), '' );

hwwa_plot_pupil_traces( use_aligned_outs ...
  , 'mask_func', wrap_mask_func ...
  , 'time_limits', [0, 800] ...
  , 'do_save', true ...
  , 'smooth_func', @(x) smoothdata(x, 'SmoothingFactor', 0.25) ...
  , 'fcats', pupil_fcats ...
  , 'prefix', prefix ...
  , 'compare_series', true ...
  , 'formats', {'svg'} ...
);

