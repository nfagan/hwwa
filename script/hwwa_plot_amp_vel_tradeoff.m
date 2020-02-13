function hwwa_plot_amp_vel_tradeoff(amp, vel, labels, varargin)

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
defaults.mask_func = @hwwa.default_mask_func;
defaults.per_monkey = false;

params = hwwa.parsestruct( defaults, varargin );

assert_ispair( amp, labels );
assert_ispair( vel, labels );

mask = get_base_mask( labels, params.mask_func );

social_v_scrambled( amp, vel, labels', mask, params );

end

function social_v_scrambled(amp, vel, labels, mask, params)

fcats = {};
pcats = { 'trial_type', 'scrambled_type' };
gcats = { 'drug' };

if ( params.per_monkey )
  fcats{end+1} = 'monkey';
  pcats{end+1} = 'monkey';
  subdir = 'per_monkey';
else
  subdir = 'across_monkeys';
end

mask = intersect( mask, find(~isnan(amp) & ~isnan(vel)) );

fig_I = findall_or_one( labels, fcats, mask );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.y_lims = [0, 5e3];
  pl.x_lims = [0, 250];
  
  a = amp(fig_I{i});
  v = vel(fig_I{i});
  l = prune( labels(fig_I{i}) );
  
  [axs, ids] = pl.scatter( a, v, l, gcats, pcats );
  [hs, store_stats] = plotlabeled.scatter_addcorr( ids, a, v );
  
%   model = fitlm( amps(ind), vels(ind) );
  
  xlabel( axs(1), 'Saccade amplitude' );
  ylabel( axs(1), 'Saccade peak velocity' );
  
  maybe_save_fig( gcf, l, [fcats, pcats, gcats], subdir, params );
end

end

function maybe_save_fig(fig, labels, spec, subdir, params)

if ( params.do_save )
  shared_utils.plot.fullscreen( fig );
  save_p = hwwa.approach_avoid_data_path( params ...
    , 'plots', 'saccade_amp_v_vel', subdir );
  dsp3.req_savefig( fig, save_p, labels, spec );
end

end


function mask = get_base_mask(labels, mask_func)

mask = hwwa.get_approach_avoid_mask( labels );
mask = mask_func( labels, mask );
mask = hwwa.find_correct_go_incorrect_nogo( labels, mask );

end