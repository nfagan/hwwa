%%  pipeline

inputs = { 'overwrite', false, 'files_containing', [] };

%%

hwwa.make_unified( inputs{:} );

%%

hwwa.make_edfs( inputs{:} );

%%

hwwa.make_labels( inputs{:} );

%%

hwwa.make_events( inputs{:} );
hwwa.make_el_events( inputs{:} );

%%

hwwa.make_edf_trials( inputs{:} ...
  , 'event',      {'iti', 'go_nogo_cue_onset'} ...
  , 'look_back',  [0, -300] ...
  , 'look_ahead', [1e3, 0] ...
);

%%

hwwa.make_iti_bounds( inputs{:} ...
  , 'bin', 1 ...
);