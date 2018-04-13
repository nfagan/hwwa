%%  pipeline

inputs = { 'overwrite', false, 'files_containing', '04' };

%%  save unified trial data

hwwa.make_unified( inputs{:} );

%%  edf -> mat

hwwa.make_edfs( inputs{:} );

%%  save spikes + lfp as mat files

hwwa.make_sync_times( inputs{:} );
hwwa.make_spikes( inputs{:} );
hwwa.make_lfp( inputs{:} );

%%  make trial labels

hwwa.make_labels( inputs{:} );

%%  extract events, convert to eyelink and plex time

hwwa.make_events( inputs{:} );
hwwa.make_el_events( inputs{:} );
hwwa.make_plex_events( inputs{:} );

%%  align pupil size, position to trial events

hwwa.make_edf_trials( inputs{:} ...
  , 'event',      {'iti', 'go_nogo_cue_onset'} ...
  , 'look_back',  [0, -300] ...
  , 'look_ahead', [1e3, 0] ...
);

%%  calculate proportion of samples in bounds, during iti

hwwa.make_iti_bounds( inputs{:} ...
  , 'bin', 1 ...
);

%%  calculate psth, raster aligned to trial events

evts = { 'go_nogo_cue_onset', 'go_target_onset' ...
  , 'reward_onset', 'go_target_offset', 'go_target_acquired' };

look_back = repmat( -0.5, 1, numel(evts) );
look_ahead = repmat( 0.5, 1, numel(evts) );

hwwa.make_psth( inputs{:} ...
  , 'overwrite', true ...
  , 'event', evts ...
  , 'look_back',  look_back ...
  , 'look_ahead', look_ahead ...
);

%%  align lfp

hwwa.make_aligned_lfp( inputs{:} ...
  , 'event',      evts ...
  , 'look_back',  look_back ...
  , 'look_ahead', look_ahead ...
  , 'window_size', 0.5 ...
);

%%  create raw power

hwwa.make_raw_power( inputs{:} ...
  , 'filter', true ...
);