function make_el_events(varargin)

defaults = hwwa.get_common_make_defaults();

event_p = hwwa.get_intermediate_dir( 'events' );
edf_p = hwwa.get_intermediate_dir( 'edf' );
output_p = hwwa.get_intermediate_dir( 'el_events' );

params = hwwa.parsestruct( defaults, varargin );

mats = hwwa.require_intermediate_mats( params.files, edf_p, params.files_containing );

for i = 1:numel(mats)
  hwwa.progress( i, numel(mats), mfilename );
  
  edf = shared_utils.io.fload( mats{i} );
  unified_filename = edf.unified_filename;
  
  events_file = fullfile( event_p, unified_filename );
  
  if ( ~shared_utils.io.fexists(events_file) )
    fprintf( '\n Skipping "%s" because the events file does not exist.', unified_filename );
    continue;
  end
  
  events = shared_utils.io.fload( events_file );
  
  output_filename = fullfile( output_p, edf.unified_filename );
  
  if ( hwwa.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  edf_sync_inds = cellfun( @(x) ~isempty(strfind(x, 'TRIAL__')), edf.Events.Messages.info );
  edf_sync_times = edf.Events.Messages.time(edf_sync_inds);
  
  mat_event_times = events.event_times;
  
  trial_start_col = events.event_key( 'new_trial' );
  mat_sync_times = mat_event_times(:, trial_start_col);
  
  nmat = numel( mat_sync_times );
  nedf = numel( edf_sync_times );
  
  assert( nmat == nedf || nedf == nmat + 1, 'Eyelink and matlab sync times do not correspond.' );
  
  edf_sync_times = edf_sync_times(1:nmat);
  mat_sync_times = mat_sync_times * 1e3;
  
  edf_event_times = nan( size(mat_event_times) );
  
  for j = 1:size(mat_event_times, 2)
    mat_times = mat_event_times(:, j) * 1e3;
    
    edf_event_times(:, j) = hwwa.clock_a_to_b( mat_times(:), mat_sync_times(:), edf_sync_times(:) );
  end
  
  events.event_times = edf_event_times;
  
  shared_utils.io.require_dir( output_p );
  save( output_filename, 'events' );
end

end