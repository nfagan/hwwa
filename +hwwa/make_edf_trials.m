function make_edf_trials(varargin)

defaults = hwwa.get_common_make_defaults();

defaults.look_back = -500;  % ms (sample rate of eyelink)
defaults.look_ahead = 500;
defaults.event = '';

event_p = hwwa.get_intermediate_dir( 'el_events' );
edf_p = hwwa.get_intermediate_dir( 'edf' );
output_p = hwwa.get_intermediate_dir( 'edf_trials' );

params = hwwa.parsestruct( defaults, varargin );

if ( isempty(params.event) )
  error( 'Specify an event name.' );
end

event_names = params.event;
look_back = params.look_back;
look_ahead = params.look_ahead;

if ( ~iscell(event_names) ), event_names = { event_names }; end

assert( numel(event_names) == numel(look_back) && numel(look_back) == numel(look_ahead) ...
  , 'Number of event names must match number of look back and look ahead.' );

mats = hwwa.require_intermediate_mats( params.files, edf_p, params.files_containing );

parfor i = 1:numel(mats)
  hwwa.progress( i, numel(mats), mfilename );
  
  edf = shared_utils.io.fload( mats{i} );
  unified_filename = edf.unified_filename;
  
  events = shared_utils.io.fload( fullfile(event_p, unified_filename) );
  
  output_filename = fullfile( output_p, unified_filename );
  
  if ( hwwa.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  %   reuse existing samples
  if ( shared_utils.io.fexists(output_filename) && params.append )
    trials = shared_utils.io.fload( output_filename );
  else
    trials = struct();
    trials.trials = containers.Map();
    trials.unified_filename = unified_filename;
  end
  
  for j = 1:numel(event_names)
    event_name = event_names{j};
    insert_one_event( trials.trials, edf, events, event_name, look_back(j), look_ahead(j) );
  end
  
  trials.params = params;
  
  shared_utils.io.require_dir( output_p );
  
  dosave( output_filename, trials );
end

end

function dosave(filepath, trials)
save( filepath, 'trials' );
end

function insert_one_event(trials, edf, events, event_name, look_back, look_ahead)

sample_types = { 'pupilSize', 'posX', 'posY' };

event_times = events.event_times(:, events.event_key(event_name));

all_samples = containers.Map();

time = edf.Samples.time;

for i = 1:numel(sample_types)

  samples = edf.Samples.(sample_types{i});

  [mat, t] = get_aligned_samples( time, samples, event_times, look_back, look_ahead );

  all_samples(sample_types{i}) = mat;
end

trials(event_name) = struct( 'samples', all_samples, 'time', t );

end

function [mat, t] = get_aligned_samples(time, samples, events, look_back, look_ahead)

start_ts = round( events + look_back );
amount = look_ahead - look_back;

mat = nan( numel(start_ts), amount + 1 );

start_inds = arrayfun( @(x) find(time == x), start_ts, 'un', false );
ns = cellfun( @numel, start_inds );
nans = isnan( start_ts );
non_ones = ns ~= 1;

assert( all(non_ones == nans), 'Start times did not match sample times.' );

others = find( ~non_ones );

t = look_back:look_back+amount;

for i = 1:numel(others)
  other = others(i);
  start_ind = start_inds{other};
  stop_ind = start_ind + amount;
  
  mat(other, :) = samples(start_ind:stop_ind);
end

end