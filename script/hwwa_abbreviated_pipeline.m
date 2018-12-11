inputs = struct();

conf = hwwa.config.load();
conf.PATHS.data_root = '/Users/Nick/Desktop/test_data_root2';

inputs.save = true;
inputs.config = conf;

hwwa.make_unified( inputs );
hwwa.make_edfs( inputs );
hwwa.make_events( inputs );
hwwa.make_el_events( inputs );
hwwa.make_alternate_el_events( inputs );
hwwa.make_labels( inputs );

%%

hwwa.make_edf_trials( inputs ...
  , 'event',        {'go_target_onset'} ...
  , 'look_back',    0 ...
  , 'look_ahead',   [1e3] ...
  , 'overwrite',    true ...
  , 'append',       true ...
);

%%

outs = hwwa_check_problematic_go_trials_looped( ...
    'config',             conf ...
  , 'kind',               'stats' ...
  , 'files_containing',   'test' ...
  , 'is_parallel',        true ...
  , 'target_event',       'go_target_onset' ...
);

%%

d1 = '~/Desktop/test_data_root/intermediates';
d2 = '~/Desktop/test_data_root2/intermediates';

subdirs = shared_utils.io.dirnames( d1, 'folders' );

diff_files = {};

for i = 1:numel(subdirs)
  fulld1 = fullfile( d1, subdirs{i} );
  fulld2 = fullfile( d2, subdirs{i} );
  
  if ( ~shared_utils.io.dexists(fulld2) )
    continue;
  end
  
  d1_filenames = shared_utils.io.dirnames( fulld1, '.mat' );
  
  for j = 1:numel(d1_filenames)
    
    d2_fullfile = fullfile( fulld2, d1_filenames{j} );
    d1_fullfile = fullfile( fulld1, d1_filenames{j} );
    
    if ( ~shared_utils.io.fexists(d2_fullfile) )
      continue;
    end
    
    d1_file = shared_utils.io.fload( d1_fullfile );
    d2_file = shared_utils.io.fload( d2_fullfile );
    
    if ( ~isequaln(d1_file, d2_file) )
      diff_files{end+1} = d1_fullfile;
    end
    
  end
  
end
