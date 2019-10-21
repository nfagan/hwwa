function hwwa_plot_time_binned_behavior(data, time, labels, varargin)

validateattributes( data, {'double'}, {'2d', 'ncols', size(data, 2)} ...
 , mfilename, 'data' );

assert( numel(time) == size(data, 2), 'Time does not correspond to data 2nd dimension.' );

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
defaults.mask_func = @(labels, mask) mask;
defaults.saline_normalize = true;
defaults.time_limits = [-inf, inf];

params = hwwa.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

per_image_category( data, labels, time, mask, params );

end

function per_image_category(data, labels, time, mask, params)

t_ind = time >= params.time_limits(1) & time <= params.time_limits(2);

subset_data = data(mask, t_ind);
subset_labels = prune( labels(mask) );

pl = plotlabeled.make_common();
pl.x = time(t_ind);
pl.smooth_func = @(x) smoothdata(x, 'smoothingfactor', 0.05);
pl.add_smoothing = true;
pl.y_lims = [0, 1];

fcats = {};
gcats = { 'drug' };
pcats = { 'scrambled_type', 'trial_type' };

[figs, axs, inds] = pl.figures( @lines, subset_data, subset_labels, fcats, gcats, pcats );
pltlabs = cellfun( @(x) subset_labels(x), inds, 'un', 0 );

if ( params.do_save )
  shared_utils.plot.fullscreen( figs );
  save_p = hwwa.approach_avoid_data_path( params, 'plots', 'p_correct_over_time' );
  dsp3.req_savefigs( figs, save_p, pltlabs, [fcats, gcats, pcats] );
end

end

function mask = get_base_mask(labels, mask_func)

mask = hwwa.get_approach_avoid_mask( labels );
mask = mask_func( labels, mask );

end