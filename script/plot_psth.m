label_p = hwwa.get_intermediate_dir( 'labels' );
psth_p = hwwa.get_intermediate_dir( 'psth' );

psth_mats = hwwa.require_intermediate_mats( psth_p );

evt = 'go_nogo_cue_onset';
% evt = 'go_target_onset';

for i = 1:numel(psth_mats)
  hwwa.progress( i, numel(psth_mats) );
  
  psth_file = shared_utils.io.fload( psth_mats{i} );
  un_filename = psth_file.unified_filename;
  labs_file = shared_utils.io.fload( fullfile(label_p, un_filename) );
  
  psth = psth_file.psth(evt);
  
  hwwa.merge_unit_labs( labs_file.labels, psth.labels );
  
  if ( i == 1 )
    psth_labs = labs_file.labels;
    psth_data = psth.data;
  else
    append( psth_labs, labs_file.labels );
    psth_data = [ psth_data; psth.data ];
  end
  
  t = psth.time;
end
%%

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.smooth_func = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.add_errors = true;
pl.one_legend = true;
pl.fig = figure(2);
pl.x = t;

plt = labeled( psth_data, psth_labs );

% only( plt, {'0410-SPK01-1'} );

lines_are = { 'id' };
panels_are = { 'trial_outcome', 'trial_type' };

pl.lines( plt, lines_are, panels_are );
