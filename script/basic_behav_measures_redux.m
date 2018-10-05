conf = hwwa.config.load();

conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/hww_gng/data';

unified_p = hwwa.get_intermediate_dir( 'unified', conf );
labels_p = hwwa.get_intermediate_dir( 'labels', conf );

label_mats = hwwa.require_intermediate_mats( [], labels_p, '10' );

summary = labeled();

delays = 0.1:0.01:0.5;
n_delays = 3;
[g_starts, g_stops] = hwwa.bin_delays( delays, n_delays );

g_starts = [ 0.1, 0.2, 0.3, 0.4 ];
g_stops = [0.19, 0.29, 0.39, 0.5 ];

for i = 1:numel(label_mats)
  hwwa.progress( i, numel(label_mats), mfilename );
  
  labels = shared_utils.io.fload( label_mats{i} );
  unified = shared_utils.io.fload( fullfile(unified_p, labels.unified_filename) );
  
  rt = [ unified.DATA(:).reaction_time ];
  rt = rt(:);
  
  labs = labels.labels;
  
  hwwa.add_day_labels( labs );
  hwwa.add_group_delay_labels( labs, g_starts, g_stops );
  hwwa.add_data_set_labels( labs );
  
  prune( labs );
  
  lab = labeled( rt, labs );
  
  append( summary, lab );
end

date_dir = datestr( now, 'mmddyy' );

stats_p = fullfile( conf.PATHS.data_root, 'analyses', 'behavior', date_dir );
plot_p = fullfile( conf.PATHS.data_root, 'plots', 'behavior', date_dir );

shared_utils.io.require_dir( plot_p );
shared_utils.io.require_dir( stats_p );

%%

interleaved_days = { '100118', '100318' };
across_blocks_days = { '100218', '100418' };

summary_labs = getlabels( summary );

addcat( summary_labs, 'delay_manipulation' );
setcat( summary_labs, 'delay_manipulation', 'interleaved', find(summary_labs, interleaved_days) );
setcat( summary_labs, 'delay_manipulation', 'across_blocks', find(summary_labs, across_blocks_days) );

summary_dat = getdata( summary );

assert_ispair( summary_dat, summary_labs );

prune( summary_labs );

%%  p correct
%
% by day, across days

uselabs = summary_labs';

mask = fcat.mask( uselabs, @find ...
  , {'tarantino_delay_check', 'initiated_true', 'interleaved', 'across_blocks'} );

[pcorr_labs, I] = keepeach( uselabs', {'date', 'trial_type', 'cue_delay'}, mask );
pcorr_dat = rowzeros( numel(I) );

for i = 1:numel(I)
  n_corr = numel( find(uselabs, 'correct_true', I{i}) );
  n_incorr = numel( find(uselabs, 'correct_false', I{i}) );

  pcorr_dat(i) = n_corr / (n_corr + n_incorr);
end

pl = plotlabeled.make_common();

xcats = { 'trial_type' };
gcats = { 'correct', 'cue_delay' };
pcats = { 'delay_manipulation' };

pl.bar( pcorr_dat, pcorr_labs, xcats, gcats, pcats );

dsp3.req_savefig( gcf, plot_p, pcorr_labs', cshorzcat(xcats, gcats, pcats), 'percent_correct' );

%%  broken cues 
%
% by day, across days

uselabs = summary_labs';

mask = fcat.mask( uselabs, @find ...
  , {'tarantino_delay_check', 'interleaved', 'across_blocks'} );

[broke_labs, I] = keepeach( uselabs', {'date', 'trial_type', 'cue_delay'}, mask );

broke_ind = rowzeros( size(broke_labs, 1), 1 );

for i = 1:numel(I)
  broke_cue_fix_ind = find( uselabs, 'broke_cue_fixation', I{i} );
  did_not_break_ind = setdiff( I{i}, find(uselabs, 'no_fixation') );
  
  broke_ind(i) = numel(broke_cue_fix_ind) / numel(did_not_break_ind);
end

pl = plotlabeled.make_common();

xcats = { 'trial_type' };
gcats = { 'correct', 'cue_delay' };
pcats = { 'delay_manipulation' };

pl.bar( broke_ind, broke_labs, xcats, gcats, pcats );

dsp3.req_savefig( gcf, plot_p, broke_labs', cshorzcat(xcats, gcats, pcats), 'abort_rate' );

%%  d' / criterion

delay_group = 'cue_delay';

specificity = { 'date', 'trial_type', delay_group };

uselabs = summary_labs';
usedat = summary_dat;

assert_ispair( usedat, uselabs );

mask = fcat.mask( uselabs, @find ...
  , {'tarantino_delay_check', 'interleaved', 'across_blocks'} );

[pcorr_labs, I] = keepeach( uselabs', specificity, mask );
data = zeros( numel(I), 1 );

for i = 1:numel(I)  
  n_correct = numel( find(uselabs, 'no_errors', I{i}) );
  n_init = numel( find(uselabs, 'initiated_true', I{i}) );
  
  data(i) = n_correct / n_init;
end

I = findall( pcorr_labs, {'drug'} );

d_prime_labs = fcat.like( pcorr_labs );
d_prime_data = zeros( size(data, 1)/2, 1 );
C_data = zeros( size(d_prime_data) );
B_data = zeros( size(C_data) );
C_prime = zeros( size(C_data) );
stp = 1;

for i = 1:numel(I)
  go_ind = find( pcorr_labs, 'go_trial', I{i} );
  nogo_ind = find( pcorr_labs, 'nogo_trial', I{i} );
  
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
  
  append( d_prime_labs, pcorr_labs, go_ind );
end

%%

kind = 'criterion';

switch ( kind )
  case 'd_prime'
    pltdat = d_prime_data;
  case 'criterion'
    pltdat = C_data;
  otherwise
    error( 'unrecognized kind "%s".', kind );
end

pltlabs = d_prime_labs';

pl = plotlabeled.make_common();

xcats = { 'trial_type' };
gcats = { 'correct', 'cue_delay' };
pcats = { 'delay_manipulation' };

pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

dsp3.req_savefig( gcf, plot_p, pltlabs', cshorzcat(xcats, gcats, pcats), kind );


