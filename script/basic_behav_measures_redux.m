conf = hwwa.config.load();

conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/hww_gng/data';

unified_p = hwwa.get_intermediate_dir( 'unified', conf );
labels_p = hwwa.get_intermediate_dir( 'labels', conf );

label_mats = hwwa.require_intermediate_mats( [], labels_p, [] );

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
  hwwa.add_drug_labels( labs );
  
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

%%  rt

do_save = false;

uselabs = summary_labs';
usedat = summary_dat;

assert_ispair( usedat, uselabs );

mask = fcat.mask( uselabs ...
  , @find, {'tarantino_drug_check', 'initiated_true', 'go_trial', 'correct_true'} ...
  , @find, hwwa_get_first_days() ...
);

pl = plotlabeled.make_common();

pl.panel_order = { 'saline' };

pl.add_points = true;
pl.points_are = 'day';
pl.marker_size = 8;
pl.marker_type = '*';

xcats = { 'trial_type' };
gcats = { 'cue_delay' };
pcats = { 'drug' };

spec = unique( cshorzcat(xcats, gcats, pcats, {'day'}) );

[rtlabs, I] = keepeach( uselabs', spec, mask );
rtdat = rownanmean( usedat, I );

pl.bar( rtdat, rtlabs, xcats, gcats, pcats );

% pl.bar( usedat(mask), uselabs(mask), xcats, gcats, pcats );

if ( do_save )
%   dsp3.req_savefig( gcf, plot_p, uselabs(mask), cshorzcat(pcats), 'rt' );
  dsp3.req_savefig( gcf, plot_p, rtlabs, cshorzcat(pcats), 'rt' );
end

%%  n initiated

do_save = false;

uselabs = summary_labs';

mask = fcat.mask( uselabs ...
  , @find, {'tarantino_drug_check', 'initiated_true'} ...
  , @find, hwwa_get_first_days() ...
);

[init_labs, I] = keepeach( uselabs', {'date'}, mask );
init_dat = rowzeros( numel(I) );

for i = 1:numel(I)
  init_dat(i) = count( uselabs, 'initiated_true', I{i} );
end

pl = plotlabeled.make_common();

pl.add_points = true;
pl.points_are = 'day';
pl.marker_size = 8;
pl.marker_type = '*';
pl.panel_order = { 'saline' };

fcats = {};
xcats = { 'drug' };
gcats = { 'correct', 'cue_delay' };
pcats = { 'delay_manipulation' };

[fs, axs, I] = pl.figures( @bar, init_dat, init_labs, fcats, xcats, gcats, pcats );
shared_utils.plot.match_ylims( axs );
shared_utils.plot.fullscreen( fs );

% pl.bar( pcorr_dat, pcorr_labs, xcats, gcats, pcats );

if ( do_save )
  for i = 1:numel(fs)
    dsp3.req_savefig( fs(i), plot_p, pcorr_labs(I{i}), cshorzcat(pcats, fcats), 'n_initiated' );
  end
end

%%  p correct
%
% by day, across days

do_save = true;

uselabs = summary_labs';

% mask = fcat.mask( uselabs, @find ...
%   , {'tarantino_delay_check', 'initiated_true', 'interleaved', 'across_blocks'} );

mask = fcat.mask( uselabs ...
  , @find, {'tarantino_drug_check', 'initiated_true'} ...
  , @find, hwwa_get_first_days() ...
);

[pcorr_labs, I] = keepeach( uselabs', {'date', 'trial_type', 'cue_delay'}, mask );
pcorr_dat = rowzeros( numel(I) );

for i = 1:numel(I)
  n_corr = numel( find(uselabs, 'correct_true', I{i}) );
  n_incorr = numel( find(uselabs, 'correct_false', I{i}) );

  pcorr_dat(i) = n_corr / (n_corr + n_incorr);
end

pl = plotlabeled.make_common();
pl.fig = figure(2);

pl.add_points = true;
pl.points_are = 'day';
pl.marker_size = 8;
pl.marker_type = '*';
pl.group_order = { 'saline' };

fcats = {};
% xcats = { 'trial_type' };
% gcats = { 'correct', 'cue_delay' };
% pcats = { 'delay_manipulation', 'drug' };

xcats = { 'cue_delay' };
gcats = { 'drug' };
pcats = { 'trial_type', 'correct' };

[fs, axs, I] = pl.figures( @bar, pcorr_dat, pcorr_labs, fcats, xcats, gcats, pcats );
shared_utils.plot.match_ylims( axs );
shared_utils.plot.fullscreen( fs );

% pl.bar( pcorr_dat, pcorr_labs, xcats, gcats, pcats );

if ( do_save )
  for i = 1:numel(fs)
    dsp3.req_savefig( fs(i), plot_p, pcorr_labs(I{i}), cshorzcat(pcats, fcats), 'percent_correct' );
  end
end

%%  broken cues 
%
% by day, across days

do_save = true;
prefix = 'tarantino';

% uselabs = summary_labs';

% mask = fcat.mask( uselabs, @find ...
%   , {'tarantino_delay_check', 'interleaved', 'across_blocks'} );

mask = fcat.mask( uselabs ...
  , @find, hwwa_get_first_days() ...
);

[broke_labs, I] = keepeach( uselabs', {'date', 'trial_type', 'cue_delay'}, mask );

broke_ind = rowzeros( size(broke_labs, 1), 1 );

for i = 1:numel(I)
  broke_cue_fix_ind = find( uselabs, 'broke_cue_fixation', I{i} );
  did_not_break_ind = setdiff( I{i}, find(uselabs, 'no_fixation') );
  
  broke_ind(i) = numel(broke_cue_fix_ind) / numel(did_not_break_ind);
end

pl = plotlabeled.make_common();

pl.add_points = true;
pl.points_are = 'day';
pl.marker_size = 8;
pl.marker_type = '*';
pl.group_order = { 'saline' };
pl.y_lims = [0, 1];

% xcats = { 'trial_type' };
% gcats = { 'correct', 'cue_delay' };
% pcats = { 'drug' };

xcats = { 'cue_delay' };
gcats = { 'drug' };
pcats = { 'trial_type', 'correct' };

pl.bar( broke_ind, broke_labs, xcats, gcats, pcats );

shared_utils.plot.fullscreen( gcf );

if ( do_save )
  dsp3.req_savefig( gcf, plot_p, broke_labs', cshorzcat(pcats), sprintf('%s_abort_rate', prefix) );
end

%%  d' / criterion

delay_group = 'cue_delay';

specificity = { 'date', 'trial_type', delay_group };

uselabs = summary_labs';
usedat = summary_dat;

assert_ispair( usedat, uselabs );

% mask = fcat.mask( uselabs, @find ...
%   , {'tarantino_delay_check', 'interleaved', 'across_blocks'} );

mask = fcat.mask( uselabs ...
  , @find, {'tarantino_drug_check'} ...
  , @find, hwwa_get_first_days() ...
);

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

kind = 'd_prime';

do_save = true;

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

pl.add_points = true;
pl.points_are = 'day';
pl.marker_size = 8;
pl.marker_type = '*';
pl.panel_order = { 'saline' };

xcats = { 'trial_type' };
gcats = { 'correct' };
pcats = { 'delay_manipulation', 'drug' };

pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

shared_utils.plot.fullscreen( gcf );

if ( do_save )
  dsp3.req_savefig( gcf, plot_p, pltlabs', cshorzcat(pcats, gcats), kind );
end


