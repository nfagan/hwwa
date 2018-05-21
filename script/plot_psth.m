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
baseline_evt = 'go_nogo_cue_onset';
pre_baseline = -0.3;
post_baseline = 0;
% norm_func = @minus;
norm_func = @rdivide;

delays = 0.1:0.01:0.5;
n_delays = 3;
[g_starts, g_stops] = hwwa.bin_delays( delays, n_delays );

do_z = true;
z_within = { 'id' };

psth_data = [];
psth_labs = fcat();

for i = 1:numel(psth_mats)
  hwwa.progress( i, numel(psth_mats) );
  
  psth_file = shared_utils.io.fload( psth_mats{i} );
  un_filename = psth_file.unified_filename;
  labs_file = shared_utils.io.fload( fullfile(label_p, un_filename) );
  
  psth = psth_file.psth(evt);
  psth_d = psth.data;
  
  if ( do_z )
    psth_d = hwwa.zscore( psth_d, psth.labels, z_within );
  end
  
  if ( do_norm )
    baseline_psth = psth_file.psth(baseline_evt);
    baseline_t = baseline_psth.time > pre_baseline & baseline_psth.time <= post_baseline;
    baseline_d = nanmean( baseline_psth.data(:, baseline_t), 2 );
    
    psth_d = norm_func( psth_d, baseline_d );
  end
  
  hwwa.merge_unit_labs( labs_file.labels, psth.labels );
  hwwa.add_day_labels( labs_file.labels );
  hwwa.add_data_set_labels( labs_file.labels );
  hwwa.add_broke_cue_labels( labs_file.labels );
  hwwa.add_group_delay_labels( labs_file.labels, g_starts, g_stops );
  
  psth_data = [ psth_data; psth_d ];
  append( psth_labs, labs_file.labels );
  
  t = psth.time;
end

prune( psth_labs );

save_p = fullfile( conf.PATHS.data_root, 'plots', 'spike', datestr(now, 'mmddyy'), evt );

%%

do_z = false;
do_save = true;

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.smooth_func = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.add_errors = true;
pl.one_legend = true;
pl.x = t;
% pl.group_order = { 'grouped_delay__0.1-0.22', 'grouped_delay__0.23-0.35' };

% panels_are = { 'id', 'trial_type' };
% lines_are = { 'trial_outcome' };
% lines_are = { 'broke_cue' };
% panels_are = { 'id' };

panels_are = { 'id', 'drug', 'trial_type' };
lines_are = { 'correct' };

% panels_are = { 'id', 'drug', 'trial_type', 'correct' };
% lines_are = { 'gcue_delay' };

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

prune( only(psth_labeled, {'dlpfc', 'initiated_true'}) );

% only( psth_labeled, {'wrong_go_nogo', 'broke_cue_fixation'} );

% collapsecat( psth_labeled, {'trial_type', 'trial_outcome'} );

collapsecat( psth_labeled, 'id' );

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

if ( do_save )
  shared_utils.io.require_dir( save_p );
  shared_utils.plot.save_fig( gcf, full_fname, {'epsc', 'png', 'fig'}, true );
end

end

%%  plot means across time

do_save = false;

t_start = -0.1;
t_stop = 0.1;
t_ind = psth_

pl = plotlabeled();
pl.error_func = @plotlabeled.nansem;
pl.summary_func = @plotlabeled.nanmean;
pl.smooth_func = @(x) smooth(x, 7);
pl.add_smoothing = true;
pl.add_errors = true;
pl.one_legend = true;
pl.x = t;
pl.group_order = { 'grouped_delay__0.1-0.22', 'grouped_delay__0.23-0.35' };

specificity = unique( [lines_are, panels_are, 'id'] );

plt_data = psth_data;

plt = labeled( plt_data, psth_labs );
only( plt, 'ro1' );
only( plt, 'initiated_true' );

collapsecat( plt, 'id' );

figs_are = { 'id' };
x_are = { 'correct' };
groups_are = { 'gcue_delay' };
panels_are = { 'trial_type' };

I = findall( plt, figs_are );

for i = 1:numel(I)
  
  subset_plt = plt(I{i});
  
  bar( pl, subset_plt, x_are, groups_are, panels_are );
  
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

do_save = true;

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

if ( do_save )
  shared_utils.io.require_dir( save_p );
  shared_utils.plot.save_fig( gcf, full_fname, {'epsc', 'png', 'fig'}, true );
end

end