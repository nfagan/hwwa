conf = hwwa.config.load();

unified_p = hwwa.get_intermediate_dir( 'unified' );
labels_p = hwwa.get_intermediate_dir( 'labels' );

label_mats = hwwa.require_intermediate_mats( [], labels_p, [] );

for i = 1:numel(label_mats)
  labels = shared_utils.io.fload( label_mats{i} );
  unified = shared_utils.io.fload( fullfile(unified_p, labels.unified_filename) );
  
  rt = [ unified.DATA(:).reaction_time ];
  rt = rt(:);
  
  lab = labeled( rt, labels.labels );
  
  if ( i == 1 )
    summary = lab;
  else
    append( summary, lab );
  end
end

saline_days = { '0215', '0221', '0228', '0302', '0303', '0305' };
serotonin_days = { '0214', '0216', '0220', '0222', '0301', '0304' };

for i = 1:numel(saline_days)
  ind = find( summary, [ saline_days{i}, '.mat' ] );
  assert( ~isempty(ind) );
  summary(ind, 'drug') = 'saline';
end
for i = 1:numel(serotonin_days)
  ind = find( summary, [ serotonin_days{i}, '.mat' ] );
  assert( ~isempty(ind) );
  summary(ind, 'drug') = '5-htp';
end

save_p = fullfile( conf.PATHS.data_root, 'plots', 'behavior', datestr(now, 'mmddyy') );
shared_utils.io.require_dir( save_p );

%%  rt, per cue delay

ind = intersect( find(summary.data > 0), find(summary, {'no_errors', 'wrong_go_nogo'}) );

rt = summary( ind );

pl = plotlabeled();
pl.error_func = @plotlabeled.sem;
pl.group_order = { 'delay__0.01' };
pl.bar( rt, 'drug', 'cue_delay', 'trial_outcome' );

shared_utils.plot.save_fig( gcf, fullfile(save_p, 'rt'), {'fig', 'epsc', 'png'}, true );

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

[~, p] = ttest( saline_data, serotonin_data );

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
stp = 1;

for i = 1:numel(I)
  go_ind = intersect( I{i}, find(p_correct, 'go_trial') );
  nogo_ind = intersect( I{i}, find(p_correct, 'nogo_trial') );
  
  go_percent = data(go_ind);
  nogo_percent = (1 - data(nogo_ind));
  
  z_hit = icdf( 'normal', go_percent, mean(go_percent), std(go_percent) );
  z_fa = icdf( 'normal', nogo_percent, mean(nogo_percent), std(nogo_percent) );
  
  d_prime = z_hit - z_fa;
  
  d_prime_data(stp:stp+numel(d_prime)-1) = d_prime;
  
  stp = stp + numel(d_prime);
  
  append( d_prime_labs, labs(go_ind) );
end

d_prime = labeled( d_prime_data, d_prime_labs );

pl = plotlabeled();
pl.error_func = @plotlabeled.std;
pl.one_legend = true;

pl.bar( d_prime, 'drug', 'cue_delay', 'trial_type' );

saline_data = d_prime_data( find(d_prime_labs, 'saline') );
serotonin_data = d_prime_data( find(d_prime_labs, '5-htp') );

[~, p] = ttest( saline_data, serotonin_data );

shared_utils.plot.save_fig( gcf, fullfile(save_p, 'd_prime'), {'fig', 'epsc', 'png'}, true );




