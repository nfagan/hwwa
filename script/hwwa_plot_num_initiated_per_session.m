function hwwa_plot_num_initiated_per_session(labels, varargin)

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
defaults.mask_func = @hwwa.default_mask_func;
defaults.per_scrambled_type = false;

params = hwwa.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

init_each = num_init_each( params );
norm_each = cssetdiff( init_each, 'unified_filename' );

[num_init, init_labels] = hwwa.num_initiated( labels, init_each, mask );
[normed_init, norm_labels] = hwwa.saline_normalize( num_init, init_labels, norm_each );

plot_normalized( normed_init, norm_labels, rowmask(norm_labels), params );
plot_raw( num_init, init_labels, rowmask(init_labels), params );

end

function plot_raw(data, labels, mask, params)

fcats = {};
pcats = {};
gcats = { 'drug' };
xcats = {};

subdir = 'raw';

bar_plots( data, labels, fcats, xcats, gcats, pcats, mask, subdir, params );

end

function plot_normalized(data, labels, mask, params)

fcats = {};
pcats = {};
gcats = { 'scrambled_type' };
xcats = {};

subdir = 'normalized';

bar_plots( data, labels, fcats, xcats, gcats, pcats, mask, subdir, params );

end

function bar_plots(data, labels, fcats, xcats, gcats, pcats, mask, subdir, params)

fig_I = findall_or_one( labels, fcats, mask );

for i = 1:numel(fig_I)
  fig = gcf();
  clf( fig );
  
  subset = data(fig_I{i});
  subset_labels = prune( labels(fig_I{i}) );
  
  pl = plotlabeled.make_common();
  pl.add_points = true;
  pl.points_are = { 'monkey' };
  pl.marker_size = 2;
  
  axs = pl.bar( subset, subset_labels, xcats, gcats, pcats );
  maybe_save_fig( fig, subset_labels, [fcats, gcats, pcats], subdir, params );
end

end

function maybe_save_fig(fig, labels, spec, subdir, params)

if ( params.do_save )
  shared_utils.plot.fullscreen( fig );
  save_p = hwwa.approach_avoid_data_path( params, 'plots', 'num_initiated', subdir );
  dsp3.req_savefig( fig, save_p, labels, spec );
end

end

function mask = get_base_mask(labels, mask_func)

require_initiated = true;

mask = hwwa.get_approach_avoid_mask( labels, {}, require_initiated );
mask = mask_func( labels, mask );

end

function each = num_init_each(params)

each = { 'unified_filename', 'monkey' };

if ( params.per_scrambled_type )
  each{end+1} = 'scrambled_type';
end

end