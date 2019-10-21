aligned_outputs = hwwa_load_edf_aligned( ...
    'start_event_name', 'go_target_onset' ...
  , 'look_back', 300 ...
  , 'look_ahead', 600 ...
  , 'is_parallel', true ...
  , 'files_containing', hwwa.approach_avoid_files() ...
);

%%

norm_x = aligned_outputs.x / 1600;
norm_y = 1 - aligned_outputs.y / 900;
labels = aligned_outputs.labels';

x_lims = [ -0.2, 1.2 ];
y_lims = [ -0.2, 1.2 ];

stp = 0.005;
win = 0.005;

mask = fcat.mask( labels, hwwa.get_approach_avoid_mask(labels) ...
  , @find, {'nogo_trial', 'correct_true'} ...
);

% heat_map_each = { 'trial_type', 'target_image_category', 'scrambled_type', 'monkey', 'drug', 'day' };
heat_map_each = { 'trial_type', 'monkey', 'drug' };

[heat_maps, heat_map_labs, x_edges, y_edges] = hwwa_make_gaze_heatmap( norm_x, norm_y, labels, heat_map_each, x_lims, y_lims, stp, win ...
  , 'mask', mask ...
);

%%

nogo_cue_rois = hwwa.linearize_roi( aligned_outputs, 'nogo_cue' );
unique_rois = unique( nogo_cue_rois, 'rows' );
assert( rows(unique_rois) == 1 );
norm_roi = unique_rois;
norm_roi([1, 3]) = norm_roi([1, 3]) / 1600;
norm_roi([2, 4]) = norm_roi([2, 4]) / 900;

%%

select_x = x_edges >= 0.2 & x_edges <= 0.75;
% select_y = y_edges >= 0.3 & y_edges <= 0.7;
select_y = y_edges <= 0.72;

% select_x = true( size(x_edges) );
% select_y = true( size(y_edges) );

subset_dat = heat_maps(:, select_y, select_x);

soc_minus_scr = ...
  @(data, labels, spec) hwwa.social_minus_scrambled( data, labels', setdiff(spec, 'scrambled_type') );

fhtp_minus_sal = ...
  @(data, labels, spec) hwwa.fhtp_minus_saline( data, labels', setdiff(spec, 'drug') );

noop = @(data, labels, spec) deal(data, labels);

max_norm = @hwwa.max_normalize;

hwwa_plot_target_onset_heatmap( subset_dat, heat_map_labs', y_edges(select_y), x_edges(select_x) ...
  , 'do_save', true ...
  , 'before_plot_func', max_norm ...
  , 'base_subdir', 'max-norm' ...
  , 'match_c_lims', true ...
  , 'overlay_rects', {norm_roi} ...
);
