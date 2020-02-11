function hwwa_plot_time_binned_behavior(data, time, labels, varargin)

validateattributes( data, {'double'}, {'2d', 'ncols', size(data, 2)} ...
 , mfilename, 'data' );

assert( numel(time) == size(data, 2), 'Time does not correspond to data 2nd dimension.' );

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
defaults.mask_func = @(labels, mask) mask;
defaults.saline_normalize = true;
defaults.time_limits = [-inf, inf];
defaults.per_monkey = false;

params = hwwa.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

social_v_scrambled_normalized( data, labels, time, mask, params );
social_v_scrambled( data, labels, time, mask, params );

end

function social_v_scrambled_normalized(data, labels, time, mask, params)

[subset_data, subset_labels, time] = make_subsets( data, labels, time, mask, params );

norm_each = { 'scrambled_type', 'trial_type', 'monkey' };
[subset_data, subset_labels] = hwwa.saline_normalize( subset_data, subset_labels', norm_each );

pl = plotlabeled.make_common();
pl.x = time;
pl.smooth_func = @(x) smoothdata(x, 'smoothingfactor', 0.2);
pl.add_smoothing = true;
pl.y_lims = [0.5, 1.5];

subdir = 'sal_vs_5htp/';

fcats = {};
gcats = { 'scrambled_type' };
pcats = { 'drug', 'trial_type' };

if ( params.per_monkey )
  fcats{end+1} = 'monkey';
  pcats = union( pcats, 'monkey' );
  subdir = sprintf( '%s_per_monkey', subdir );
end

make_line_figures( pl, subset_data, subset_labels, fcats, gcats, pcats, subdir, params );

end

function social_v_scrambled(data, labels, time, mask, params)

[subset_data, subset_labels, time] = make_subsets( data, labels, time, mask, params );

pl = plotlabeled.make_common();
pl.x = time;
pl.smooth_func = @(x) smoothdata(x, 'smoothingfactor', 0.05);
pl.add_smoothing = true;
pl.y_lims = [0, 1];

subdir = 'social_v_scrambled/';

fcats = {};
gcats = { 'drug' };
pcats = { 'scrambled_type', 'trial_type' };

if ( params.per_monkey )
  fcats{end+1} = 'monkey';
  pcats = union( pcats, 'monkey' );
  subdir = sprintf( '%s_per_monkey', subdir );
end

make_line_figures( pl, subset_data, subset_labels, fcats, gcats, pcats, subdir, params );

end

function [data, labels, time] = make_subsets(data, labels, time, mask, params)

t_ind = time >= params.time_limits(1) & time <= params.time_limits(2);

data = data(mask, t_ind);
labels = prune( labels(mask) );
time = time(t_ind);

end

function make_line_figures(pl, subset_data, subset_labels, fcats, gcats, pcats, subdir, params)

fig_I = findall_or_one( subset_labels, fcats );

for i = 1:numel(fig_I)
  fig = gcf();
  clf( fig );
  
  fig_data = subset_data(fig_I{i}, :);
  fig_labels = prune( subset_labels(fig_I{i}) );
  
  [axs, ~, inds] = pl.lines( fig_data, fig_labels, gcats, pcats );
  [ps, plot_hs] = dsp3.compare_series( axs, inds, fig_data, @signrank ...
    , 'x', pl.x ...
    , 'fig', gcf ...
    , 'p_levels', 0.05 ...
  );

  non_empty_plot_hs = cellfun( @(x) x(cellfun(@(y) ~isempty(y), x)), plot_hs, 'un', 0 );
  cellfun( @(x) cellfun(@(x) set(x, 'markersize', 0.5), x), non_empty_plot_hs );

  if ( params.do_save )
    shared_utils.plot.fullscreen( fig );
    save_p = hwwa.approach_avoid_data_path( params, 'plots', 'p_correct_over_time', subdir );
    dsp3.req_savefig( fig, save_p, fig_labels, [fcats, gcats, pcats] );
  end
end

end

function mask = get_base_mask(labels, mask_func)

mask = hwwa.get_approach_avoid_mask( labels );
mask = mask_func( labels, mask );

end