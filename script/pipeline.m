%%  pipeline

inputs = { 'overwrite', false, 'files_containing', '0410' };

%%

hwwa.make_unified( inputs{:} );

%%

hwwa.make_edfs( inputs{:} );

%%

hwwa.make_sync_times( inputs{:} );
hwwa.make_spikes( inputs{:} );

%%

hwwa.make_labels( inputs{:} );

%%

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

hwwa.make_psth( inputs{:} ...
  , 'event',      {'go_nogo_cue_onset', 'go_target_onset'} ...
  , 'look_back',  [-0.5, -0.5] ...
  , 'look_ahead', [0.5, 0.5] ...
);

