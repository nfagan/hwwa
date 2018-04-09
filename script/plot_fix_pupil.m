conf = hwwa.config.load();
save_p = fullfile( conf.PATHS.data_root, 'plots', 'pupil', datestr(now, 'mmddyy') );

trials_p = hwwa.get_intermediate_dir( 'edf_trials' );
label_p = hwwa.get_intermediate_dir( 'labels' );

trials_mats = hwwa.require_intermediate_mats( trials_p );

all_pupil = [];

for i = 1:numel(trials_mats)
  hwwa.progress( i, numel(trials_mats) );
  
  trials = shared_utils.io.fload( trials_mats{i} );
  labs = shared_utils.io.fload( fullfile(label_p, trials.unified_filename) );
  
  pupil = trials.trials('go_nogo_cue_onset').samples('pupilSize');
  t = trials.trials('go_nogo_cue_onset').time;
  
  if ( i == 1 )
    all_labels = fcat.like( labs.labels );
  end
  
  append( all_labels, labs.labels );
  all_pupil = [ all_pupil; pupil ];
end

hwwa.add_drug_labels( all_labels );

%%

do_zscore = true;

if ( do_zscore )
  I = findall( all_labels, 'date' );

  z_pupil = all_pupil;

  for i = 1:numel(I)
    subset = all_pupil(I{i}, :);
    z_pupil(I{i}, :) = (subset - nanmean(subset(:))) / nanstd(subset(:));
  end
  z_str = 'z_scored';
else
  z_pupil = all_pupil;
  z_str = 'non_z';
end

dat = labeled( z_pupil, all_labels );

eachindex( dat, {'date', 'trial_type'}, @rownanmean );

prune( dat );

pl = plotlabeled();
pl.x = t + 300;
% pl.y_lims = [ 2e3, 5e3 ];
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.smooth_func = @(x) smooth(x, 100);
pl.add_smoothing = true;

% collapsecat( dat, setdiff(getcats(dat), {'drug', 'trial_type', 'cue_delay'}) );

axs = lines( pl, dat, 'drug', {'trial_type'} );

if ( do_zscore )
  ylabel( axs(1), 'z-pupil' );
else
  ylabel( axs(1), 'non-normalized pupil' );
end

xlabel( axs(1), 'time (ms) from fixation' );

shared_utils.io.require_dir( save_p );
fname = sprintf( '%s_%s_pupil', z_str, strjoin(incat(dat, {'drug', 'trial_type'}), '_') );

shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'epsc', 'fig', 'png'}, true );


