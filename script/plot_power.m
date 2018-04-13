conf = hwwa.config.load();

label_p = hwwa.get_intermediate_dir( 'labels' );
power_p = hwwa.get_intermediate_dir( 'raw_power' );

power_mats = hwwa.require_intermediate_mats( power_p );

% evt = 'go_target_onset';
% evt = 'go_target_acquired';
% evt = 'go_nogo_cue_onset';
% evt = 'reward_onset';
evt = 'go_target_offset';

do_norm = true;

for i = 1:numel(power_mats)
  hwwa.progress( i, numel(power_mats) );
  
  power_file = shared_utils.io.fload( power_mats{i} );
  un_filename = power_file.unified_filename;
  labs_file = shared_utils.io.fload( fullfile(label_p, un_filename) );
  
  measure = power_file.measure(evt);
  psth_d = measure.data;
  
  hwwa.merge_unit_labs( labs_file.labels, measure.labels );
  
  if ( do_norm )
    baseline_p = power_file.measure('go_nogo_cue_onset');
    baseline_ind = baseline_p.time >= -0.3 & baseline_p.time <= 0;
    baseline_d = nanmean( baseline_p.data(:, :, baseline_ind), 3 );
    
    for j = 1:size(psth_d, 3)
      psth_d(:, :, j) = psth_d(:, :, j) - baseline_d;
    end
  end
  
  if ( i == 1 )
    psth_labs = labs_file.labels;
    psth_data = psth_d;
  else
    append( psth_labs, labs_file.labels );
    psth_data = [ psth_data; psth_d ];
  end
  
  t = measure.time;
end

did_break_ind = find( psth_labs, 'broke_cue_fixation' );
did_not_break = setdiff( 1:size(psth_labs, 1), did_break_ind );

addcat( psth_labs, 'broke_cue' );
setcat( psth_labs, 'broke_cue', 'broke_true', did_break_ind );
setcat( psth_labs, 'broke_cue', 'broke_false', did_not_break );

prune( psth_labs );

save_p = fullfile( conf.PATHS.data_root, 'plots', 'raw_power', datestr(now, 'mmddyy'), evt );

%%

cont = SignalContainer( psth_data, SparseLabels.from_fcat(psth_labs) );

cont.frequencies = measure.frequencies;
cont.start = t(1);
cont.stop = t(end);
cont.window_size = measure.window_size;
cont.step_size = measure.step_size;

%%  correct - incorrect

meaned = each1d( cont, {'trial_type', 'trial_outcome'}, @rowops.nanmean );
meaned = rm( meaned, 'no_choice' );
meaned = collapse( meaned, 'error' );

sub1 = meaned({'go_trial', 'go_choice'}) - meaned({'go_trial', 'nogo_choice'});
sub2 = meaned({'nogo_trial', 'nogo_choice'}) - meaned({'nogo_trial', 'go_choice'});
meaned = [ sub1; sub2 ];

meaned = add_field( meaned, 'epochs', evt );

meaned.spectrogram( {'trial_type', 'trial_outcome'} ...
  , 'frequencies', [0, 100] ...
  , 'shape', [1, 2] ...
  );

shared_utils.io.require_dir( save_p );

fname = strjoin( flat_uniques(meaned, {'trial_type', 'trial_outcome'}), '_' );
full_fname = fullfile( save_p, fname );
shared_utils.plot.save_fig( gcf, full_fname, {'epsc', 'png', 'fig'}, true );

%%  go - nogo

meaned = each1d( cont, {'trial_type', 'trial_outcome'}, @rowops.nanmean );
meaned = rm( meaned, 'no_choice' );
meaned = collapse( meaned, 'error' );

sub1 = meaned({'go_trial', 'go_choice'}) - meaned({'nogo_trial', 'nogo_choice'});
sub2 = meaned({'nogo_trial', 'go_choice'}) - meaned({'go_trial', 'nogo_choice'});

sub1( 'trial_type' ) = 'correct_go minus correct nogo';
sub2( 'trial_type' ) = 'incorrect_go minus incorrect nogo';

meaned = [ sub1; sub2 ];

meaned = add_field( meaned, 'epochs', evt );

meaned.spectrogram( {'trial_type', 'trial_outcome'} ...
  , 'frequencies', [0, 100] ...
  , 'shape', [1, 2] ...
  );


