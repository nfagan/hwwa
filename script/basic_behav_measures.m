conf = hwwa.config.load();

unified_p = hwwa.get_intermediate_dir( 'unified' );
labels_p = hwwa.get_intermediate_dir( 'labels' );

label_mats = hwwa.require_intermediate_mats( [], labels_p, [] );

summary = labeled();

for i = 1:numel(label_mats)
  hwwa.progress( i, numel(label_mats), mfilename );
  
  labels = shared_utils.io.fload( label_mats{i} );
  unified = shared_utils.io.fload( fullfile(unified_p, labels.unified_filename) );
  
  rt = [ unified.DATA(:).reaction_time ];
  rt = rt(:);
  
  lab = labeled( rt, labels.labels );
  
  append( summary, lab );
end

date_dir = datestr( now, 'mmddyy' );

stats_p = fullfile( conf.PATHS.data_root, 'analyses', 'behavior', date_dir );
save_p = fullfile( conf.PATHS.data_root, 'plots', 'behavior', date_dir );
shared_utils.io.require_dir( save_p );
shared_utils.io.require_dir( stats_p );

%%  rt, per cue delay

ind = intersect( find(summary.data > 0), find(summary, {'no_errors', 'wrong_go_nogo'}) );

rt = prune( summary(ind) );

rt = eachindex( rt', {'date', 'cue_delay', 'trial_outcome'}, @rownanmean );

delay_strs = rt('cue_delay');
delays = shared_utils.container.cat_parse_double( 'delay__', delay_strs );
[~, sort_i] = sort( delays );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.group_order = delay_strs(sort_i);
pl.bar( rt, 'drug', 'cue_delay', 'trial_outcome' );

fname = strjoin( incat(rt, {'date', 'drug'}), '_' );
fname = sprintf( 'rt_%s', fname );

shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'fig', 'epsc', 'png'}, true );

%%  rt anova

full_stats_p = fullfile( stats_p, 'rt' );
shared_utils.io.require_dir( full_stats_p );

grps = { 'cue_delay', 'drug' };

hwwa.write_anova_tables( rt, grps, full_stats_p, '' );

%%  means + devs

grps = { 'cue_delay' };
hwwa.write_anova_summary_tables( rt, grps, full_stats_p );

%%  rt, across cue delays

ind = intersect( find(summary.data > 0), find(summary, {'no_errors', 'wrong_go_nogo'}) );

rt = summary( ind );
collapsecat( rt, 'cue_delay' );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.group_order = { 'delay__0.01' };
pl.bar( rt, 'drug', 'trial_outcome', 'cue_delay' );

%%  n initiated

specificity = { 'date' };

[labs, I, C] = keepeach( getlabels(summary), specificity );
data = zeros( numel(I), 1 );
initiated_trials = find( summary, {'no_errors', 'wrong_go_nogo'} );
for i = 1:numel(I)
  data(i) = numel( intersect(I{i}, initiated_trials) );
end

n_initiated = labeled( data, labs );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;

pl.bar( n_initiated, 'drug', 'trial_type', 'trial_outcome' );

shared_utils.plot.save_fig( gcf, fullfile(save_p, 'n_initiated_all_trials') ...
  , {'fig', 'epsc', 'png'}, true );

saline_data = data( find(n_initiated, 'saline') );
serotonin_data = data( find(n_initiated, '5-htp') );

sal_means = mean( saline_data );
sal_devs = std( saline_data );
htp_means = mean( serotonin_data );
htp_devs = std( serotonin_data );

[~, p] = ttest( saline_data, serotonin_data );

%%  broken cues 

labels = getlabels( summary );

[y, I] = keepeach( labels', {'date', 'trial_type', 'cue_delay'} );
data = zeros( size(y, 1), 1 );

for i = 1:numel(I)
  initiated_ind = intersect( I{i}, find(labels, 'initiated_true') );
  broke_fix_ind = intersect( I{i}, find(labels, 'broke_cue_fixation') );
  
  data(i) = numel(broke_fix_ind) / numel(initiated_ind);
end

p_broke_cue = labeled( data, y );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.panel_order = 'delay__0.01';

pl.bar( p_broke_cue, 'drug', 'trial_type', 'cue_delay' );

fname = strjoin( incat(p_broke_cue, {'drug', 'trial_type', 'cue_delay'}), '_' );
fname = sprintf( 'p_broke_cue_fix_%s', fname );

shared_utils.plot.save_fig( gcf, fullfile(save_p, fname), {'fig', 'epsc', 'png'}, true );

%%  broke cue anova

full_stats_p = fullfile( stats_p, 'broke_cue' );
shared_utils.io.require_dir( full_stats_p );

grps = { 'drug', 'cue_delay' };

hwwa.write_anova_tables( p_broke_cue, grps, full_stats_p, 'no_cue_delay' );

%%  means + devs

grps = { 'cue_delay' };
hwwa.write_anova_summary_tables( p_broke_cue, grps, full_stats_p );

%%  percent correct

specificity = { 'date', 'trial_type', 'cue_delay' };

[labs, I, C] = keepeach( getlabels(summary), specificity );
data = zeros( numel(I), 1 );
correct_trials = find( summary, 'no_errors' );
initiated_trials = find( summary, {'no_errors', 'wrong_go_nogo'} );
for i = 1:numel(I)
  n_correct = numel( intersect(I{i}, correct_trials) );
  n_init = numel( intersect(I{i}, initiated_trials) );
  
  data(i) = n_correct / n_init;
end

p_correct = labeled( data, labs );

% only( p_correct, {'delay__0.1', 'delay__0.5'} );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.one_legend = true;
pl.group_order = { 'delay__0.01' };

pl.bar( p_correct, 'drug', 'cue_delay', 'trial_type' );

shared_utils.plot.save_fig( gcf, fullfile(save_p, 'p_correct') ...
  , {'fig', 'epsc', 'png'}, true );

%%

full_stats_p = fullfile( stats_p, 'p_correct' );
shared_utils.io.require_dir( full_stats_p );

grps = { 'trial_type' };

hwwa.write_anova_tables( p_correct, grps, full_stats_p, '' );

%%  means + devs

grps = { 'trial_type' };
hwwa.write_anova_summary_tables( p_correct, grps, full_stats_p );

%% number correct

specificity = { 'date', 'trial_type', 'cue_delay' };

[labs, I, C] = keepeach( getlabels(summary), specificity );
data = zeros( numel(I), 1 );
correct_trials = find( summary, 'no_errors' );
for i = 1:numel(I)
  n_correct = numel( intersect(I{i}, correct_trials) );
  data(i) = n_correct;
end

n_correct = labeled( data, labs );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.one_legend = true;
pl.group_order = { 'delay__0.01' };

pl.bar( n_correct, 'drug', 'cue_delay', 'trial_type' );

fname = strjoin( incat(n_correct, {'drug', 'trial_type'}), '_' );
fname = sprintf( 'ncorrect_%s', fname );

shared_utils.plot.save_fig( gcf, fullfile(save_p, fname) ...
  , {'fig', 'epsc', 'png'}, true );

%%  d'

specificity = { 'date', 'trial_type' };

all_labs = getlabels( summary );
[labs, I, C] = keepeach( getlabels(summary), specificity );
data = zeros( numel(I), 1 );
correct_trials = find( summary, 'no_errors' );
initiated_trials = find( summary, {'no_errors', 'wrong_go_nogo'} );
for i = 1:numel(I)
  n_correct = numel( intersect(I{i}, correct_trials) );
  n_init = numel( intersect(I{i}, initiated_trials) );
  
  data(i) = n_correct / n_init;
end

p_correct = labeled( data, labs );

z_each = { 'drug' };

[~, I] = keepeach( getlabels(p_correct), z_each );

d_prime_labs = fcat.like( labs );
d_prime_data = zeros( size(data, 1)/2, 1 );
C_data = zeros( size(d_prime_data) );
B_data = zeros( size(C_data) );
C_prime = zeros( size(C_data) );
stp = 1;

for i = 1:numel(I)
  go_ind = intersect( I{i}, find(p_correct, 'go_trial') );
  nogo_ind = intersect( I{i}, find(p_correct, 'nogo_trial') );
  
  go_percent = data(go_ind);
  nogo_percent = (1 - data(nogo_ind));
  
  z_hit = norminv( go_percent, mean(go_percent), std(go_percent) );
  z_fa = norminv( nogo_percent, mean(nogo_percent), std(nogo_percent) );
  
  d_prime = z_hit - z_fa;
  
  c_dat = -0.5 .* (z_hit + z_fa);
  
  b = exp( c_dat .* d_prime );
  c_prime = c_dat ./ d_prime;
  
  assign_seq = stp:stp+numel(d_prime)-1;
  
  d_prime_data(assign_seq) = d_prime;
  C_data(assign_seq) = c_dat;
  B_data(assign_seq) = b;
  C_prime(assign_seq) = c_prime;
  
  stp = stp + numel(d_prime);
  
  append( d_prime_labs, labs(go_ind) );
end

%%

plot_type = 'b';

switch ( plot_type )
  case 'd_prime'
    plt_data = d_prime_data;
  case 'c'
    plt_data = C_data;
  case 'c_prime'
    plt_data = C_prime;
  case 'b'
    plt_data = B_data;
  otherwise
    error( 'Unrecognized plot type "%s".', plot_type );
end

plt_sdt = labeled( plt_data, d_prime_labs );

pl = plotlabeled();
pl.error_func = @plotlabeled.std;
pl.one_legend = true;

pl.bar( plt_sdt, 'drug', 'cue_delay', 'trial_type' );

means = eachindex( plt_sdt', 'drug', @rowmean );
devs = each( plt_sdt', 'drug', @(x) std(x, [], 1) );

m_t = table( Container.from(means), 'drug' );
d_t = table( Container.from(devs), 'drug' );

saline_data = plt_data( find(d_prime_labs, 'saline') );
serotonin_data = plt_data( find(d_prime_labs, '5-htp') );

sal_mean = mean( saline_data );
htp_mean = mean( serotonin_data );
sal_dev = std( saline_data );
htp_dev = std( serotonin_data );

[~, p, ~, stats] = ttest( saline_data, serotonin_data );
stats = struct2table( stats );
stats(:, 'p') = { p };

shared_utils.plot.save_fig( gcf, fullfile(save_p, plot_type), {'fig', 'epsc', 'png'}, true );

writetable( m_t, fullfile(stats_p, ['means_', plot_type, '.csv']), 'WriteRowNames', true );
writetable( d_t, fullfile(stats_p, ['devs_', plot_type, '.csv']), 'WriteRowNames', true );
writetable( stats, fullfile(stats_p, ['stats_', plot_type, '.csv']), 'WriteRowNames', true );




