conf = hwwa.config.load();
save_p = fullfile( conf.PATHS.data_root, 'plots', 'iti_looks', datestr(now, 'mmddyy') );

bounds_p = hwwa.get_intermediate_dir( 'iti_bounds' );
label_p = hwwa.get_intermediate_dir( 'labels' );

bound_mats = hwwa.require_intermediate_mats( bounds_p );

all_props = [];

for i = 1:numel(bound_mats)
  hwwa.progress( i, numel(bound_mats) );
  
  bounds = shared_utils.io.fload( bound_mats{i} );
  
  un_file = bounds.unified_filename;
  
  labels = shared_utils.io.fload( fullfile(label_p, un_file) );
  labels = labels.labels;
  
  if ( i == 1 )
    all_labels = fcat.like( labels );
  end
  
  [y, I] = keepeach( labels', {'date', 'trial_type'} );
  
  for j = 1:numel(I)
    N = numel( intersect(I{j}, find(labels, {'no_errors', 'wrong_go_nogo'})) );
    prop = sum( bounds.bounds(I{j}, :), 1 ) / N;
    all_props = [ all_props; prop ];
  end
  
  append( all_labels, y );
  
  t = bounds.time;
end

hwwa.add_drug_labels( all_labels );

%%

dat = labeled( all_props, all_labels );

pl = plotlabeled();
pl.x = t;
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.smooth_func = @(x) smooth(x, 100);
pl.add_smoothing = true;
pl.panel_order = { 'delay__0.01', 'go_trial' };
pl.y_lims = [0, 0.6];

collapsecat( dat, setdiff(getcats(dat), {'drug', 'cue_delay'}) );

prune( dat );

axs = lines( pl, dat, 'drug', {'trial_type'} );

xlabel( axs(1), 'time (ms) from iti onset' );
ylabel( axs(1), 'p in fix-square bounds' );

shared_utils.io.require_dir( save_p );
fname = strjoin( incat(dat, {'drug', 'trial_type'}), '_' );

shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'epsc', 'png', 'fig'}, true );

