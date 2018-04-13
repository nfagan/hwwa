conf = hwwa.config.load();

label_p = hwwa.get_intermediate_dir( 'labels' );
psth_p = hwwa.get_intermediate_dir( 'psth' );

psth_mats = hwwa.require_intermediate_mats( psth_p );

evt = 'go_target_onset';
% evt = 'go_target_acquired';
% evt = 'go_nogo_cue_onset';
% evt = 'reward_onset';
% evt = 'go_target_offset';

do_norm = false;

for i = 1:numel(psth_mats)
  hwwa.progress( i, numel(psth_mats) );
  
  psth_file = shared_utils.io.fload( psth_mats{i} );
  un_filename = psth_file.unified_filename;
  labs_file = shared_utils.io.fload( fullfile(label_p, un_filename) );
  
  psth = psth_file.psth(evt);
  psth_d = psth.data;
  
  if ( do_norm )
    baseline_psth = psth_file.psth('go_nogo_cue_onset');
    baseline_t = baseline_psth.time > -0.3 & baseline_psth.time <= 0;
    baseline_d = mean( baseline_psth.data(:, baseline_t), 2 );
    
    psth_d = psth_d - baseline_d;
  end
  
  hwwa.merge_unit_labs( labs_file.labels, psth.labels );
  
  if ( i == 1 )
    psth_labs = labs_file.labels;
    psth_data = psth_d;
  else
    append( psth_labs, labs_file.labels );
    psth_data = [ psth_data; psth_d ];
  end
  
  t = psth.time;
end

did_break_ind = find( psth_labs, 'broke_cue_fixation' );
did_not_break = setdiff( 1:size(psth_labs, 1), did_break_ind );

addcat( psth_labs, 'broke_cue' );
setcat( psth_labs, 'broke_cue', 'broke_true', did_break_ind );
setcat( psth_labs, 'broke_cue', 'broke_false', did_not_break );

prune( psth_labs );

save_p = fullfile( conf.PATHS.data_root, 'plots', 'spike', datestr(now, 'mmddyy'), evt );

%%

do_z = false;

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.smooth_func = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.add_errors = true;
pl.one_legend = true;
pl.x = t;

% panels_are = { 'id', 'trial_type' };
% lines_are = { 'trial_outcome' };
% lines_are = { 'broke_cue' };
% panels_are = { 'id' };

panels_are = { 'id' };
lines_are = { 'correct' };

specificity = unique( [lines_are, panels_are, 'id'] );

plt_data = psth_data;

if ( do_z )
  z_each = specificity;
  
  I = findall( psth_labs, specificity );
  
  for i = 1:numel(I)
    subset_data = plt_data(I{i}, :);
    means = nanmean( subset_data );
    devs = nanstd( subset_data );
    plt_data(I{i}, :) = (subset_data - means) ./ devs;
  end
end

psth_labeled = labeled( plt_data, psth_labs );

% only( psth_labeled, {'wrong_go_nogo', 'broke_cue_fixation'} );

% collapsecat( psth_labeled, {'trial_type', 'trial_outcome'} );

I = findall( psth_labeled, 'id' );

for i = 1:numel(I)

plt = prune( psth_labeled(I{i}) );

ind = find( plt, 'no_choice' );

keep( plt, setdiff(1:size(plt, 1), ind) );

axs = pl.lines( plt, lines_are, panels_are );

arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
arrayfun( @(x) plot(x, [0; 0], get(x, 'ylim'), 'k--'), axs );
arrayfun( @(x) xlabel(x, sprintf('Time (s) from %s', strrep(evt, '_', ' '))), axs );

fname = strjoin( incat(plt, specificity), '_' );
fname = sprintf( 'psth_%s', fname );
full_fname = fullfile( save_p, fname );

shared_utils.io.require_dir( save_p );
shared_utils.plot.save_fig( gcf, full_fname, {'epsc', 'png', 'fig'}, true );

end

%%  plot targ onset

pl = ContainerPlotter();
pl.error_function = @(x, y) plotlabeled.nansem(x);
pl.summary_function = @(x, y) nanmean( x, 1 );
pl.smooth_function = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.x = t;
pl.marker_size = 8;
pl.add_ribbon = true;
pl.compare_series = true;
pl.p_correct_type = 'fdr';

panels_are = { 'id' };
lines_are = { 'correct' };

specificity = unique( [lines_are, panels_are, 'id'] );

psth_labeled = labeled( psth_data, psth_labs );

I = findall( psth_labeled, 'id' );

for i = 1:numel(I)

plt = prune( psth_labeled(I{i}) );

ind = find( plt, 'no_choice' );

keep( plt, setdiff(1:size(plt, 1), ind) );

axs = pl.plot( Container.from(plt), lines_are, panels_are );

arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
arrayfun( @(x) plot(x, [0; 0], get(x, 'ylim'), 'k--'), axs );
arrayfun( @(x) xlabel(x, sprintf('Time (s) from %s', strrep(evt, '_', ' '))), axs );

fname = strjoin( incat(plt, specificity), '_' );
fname = sprintf( 'psth_%s', fname );
full_fname = fullfile( save_p, fname );

shared_utils.io.require_dir( save_p );
shared_utils.plot.save_fig( gcf, full_fname, {'epsc', 'png', 'fig'}, true );

end

%%  cue onset | target onset

pl = ContainerPlotter();
pl.error_function = @(x, y) plotlabeled.nansem(x);
pl.summary_function = @(x, y) nanmean( x, 1 );
pl.smooth_function = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.x = t;
pl.marker_size = 8;
pl.add_ribbon = true;
pl.compare_series = true;
pl.p_correct_type = 'fdr';

panels_are = { 'id', 'trial_type' };
lines_are = { 'trial_outcome' };

specificity = unique( [lines_are, panels_are, 'id'] );

psth_labeled = labeled( psth_data, psth_labs );

I = findall( psth_labeled, 'id' );

for i = 1:numel(I)

plt = prune( psth_labeled(I{i}) );

ind = find( plt, 'no_choice' );

keep( plt, setdiff(1:size(plt, 1), ind) );

axs = pl.plot( Container.from(plt), lines_are, panels_are );

arrayfun( @(x) set(x, 'nextplot', 'add'), axs );
arrayfun( @(x) plot(x, [0; 0], get(x, 'ylim'), 'k--'), axs );
arrayfun( @(x) xlabel(x, sprintf('Time (s) from %s', strrep(evt, '_', ' '))), axs );

fname = strjoin( incat(plt, specificity), '_' );
fname = sprintf( 'psth_%s', fname );
full_fname = fullfile( save_p, fname );

shared_utils.io.require_dir( save_p );
shared_utils.plot.save_fig( gcf, full_fname, {'epsc', 'png', 'fig'}, true );

end