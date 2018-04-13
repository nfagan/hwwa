function make_events(varargin)

defaults = hwwa.get_common_make_defaults();

input_p = hwwa.get_intermediate_dir( 'unified' );
output_p = hwwa.get_intermediate_dir( 'events' );

params = hwwa.parsestruct( defaults, varargin );

mats = hwwa.require_intermediate_mats( params.files, input_p, params.files_containing );

for i = 1:numel(mats)
  hwwa.progress( i, numel(mats), mfilename );
  
  unified = shared_utils.io.fload( mats{i} );
  unified_filename = unified.unified_filename;
  
  output_filename = fullfile( output_p, unified.unified_filename );
  
  if ( hwwa.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  evts = [ unified.DATA(:).events ];
  evt_names = sort( fieldnames(evts) );
  
  event_times = zeros( numel(evts), numel(evt_names) );
  event_key = containers.Map( 'keytype', 'char', 'valuetype', 'double' );
  
  for j = 1:numel(evt_names)
    evt_name = evt_names{j};
    event_times(:, j) = [ evts(:).(evt_name) ];
    event_key(evt_name) = j;
  end
  
  has_iti = any( strcmp(event_key, 'iti') );
  
  %   older sessions don't have an iti event time, but the preceding state
  %   is reward onset -- so just add the reward state time
  if ( has_iti )
    reward_dur = unified.opts.TIMINGS.time_in.reward;
    error_dur = unified.opts.TIMINGS.time_in.error_go_nogo;
    
    reward_ts = event_times(:, event_key('reward_onset'));
    error_ts = event_times(:, event_key('go_target_offset'));
    
    use_error_ts = strcmp( {unified.DATA(:).error}, 'wrong_go_nogo' );
    
    iti_ts = reward_ts + reward_dur;
    iti_ts(use_error_ts(:)) = error_ts(use_error_ts(:)) + error_dur;
    
    current_n = numel( evt_names );
    event_key('iti') = current_n + 1;
    event_times(:, end+1) = iti_ts;
  end
  
  events = struct();
  events.unified_filename = unified_filename;
  events.event_key = event_key;
  events.event_times = event_times;
  
  shared_utils.io.require_dir( output_p );
  
  save( output_filename, 'events' );
end

end