function [results, params] = make_edf_trials(varargin)

defaults = hwwa.make.defaults.edf_trials();

params = hwwa.parsestruct( defaults, varargin );

event_subdir = params.event_subdir;
event_subdir = validatestring( event_subdir, {'el_events', 'edf_events'} );

params.event_subdir = event_subdir;

inputs = { 'edf', event_subdir };
output = params.output_directory;

[~, loop_runner] = hwwa.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @hwwa.make.edf_trials, params );

end
% 
% 
% 
% 
% 
% defaults = hwwa.get_common_make_defaults();
% 
% defaults.look_back = -500;  % ms (sample rate of eyelink)
% defaults.look_ahead = 500;
% defaults.event = '';
% defaults.event_subdir = 'el_events';
% 
% params = hwwa.parsestruct( defaults, varargin );
% params.event_subdir = validatestring( params.event_subdir, {'el_events', 'edf_events'} );
% 
% conf = params.config;
% 
% event_p = hwwa.get_intermediate_dir( params.event_subdir, conf );
% edf_p = hwwa.get_intermediate_dir( 'edf', conf );
% output_p = hwwa.get_intermediate_dir( 'edf_trials', conf );
% 
% if ( isempty(params.event) )
%   error( 'Specify an event name.' );
% end
% 
% event_names = params.event;
% look_back = params.look_back;
% look_ahead = params.look_ahead;
% 
% if ( ~iscell(event_names) ), event_names = { event_names }; end
% 
% assert( numel(event_names) == numel(look_back) && numel(look_back) == numel(look_ahead) ...
%   , 'Number of event names must match number of look back and look ahead.' );
% 
% mats = hwwa.require_intermediate_mats( params.files, edf_p, params.files_containing );
% 
% parfor i = 1:numel(mats)
%   hwwa.progress( i, numel(mats), mfilename );
%   
%   edf = shared_utils.io.fload( mats{i} );
%   unified_filename = edf.unified_filename;
%   
%   events = shared_utils.io.fload( fullfile(event_p, unified_filename) );
%   
%   output_filename = fullfile( output_p, unified_filename );
%   
%   if ( hwwa.conditional_skip_file(output_filename, params.overwrite) )
%     continue;
%   end
%   
%   %   reuse existing samples
%   if ( shared_utils.io.fexists(output_filename) && params.append )
%     trials = shared_utils.io.fload( output_filename );
%   else
%     trials = struct();
%     trials.trials = containers.Map();
%     trials.unified_filename = unified_filename;
%   end
%   
%   try
%     for j = 1:numel(event_names)
%       event_name = event_names{j};
%       insert_one_event( trials.trials, edf, events, event_name, look_back(j), look_ahead(j) );
%     end
% 
%     trials.params = params;
% 
%     shared_utils.io.require_dir( output_p );
% 
%     dosave( output_filename, trials );
%   catch err
%     hwwa.print_fail_warn( unified_filename, err.message );
%     continue;
%   end
% end
% 
% end
% 
% function dosave(filepath, trials)
% save( filepath, 'trials' );
% end
% 
% function insert_one_event(trials, edf, events, event_name, look_back, look_ahead)
% 
% sample_types = { 'pupilSize', 'posX', 'posY' };
% 
% event_times = events.event_times(:, events.event_key(event_name));
% 
% all_samples = containers.Map();
% 
% time = edf.Samples.time;
% 
% for i = 1:numel(sample_types)
% 
%   samples = edf.Samples.(sample_types{i});
% 
%   [mat, t, fs] = get_aligned_samples( time, samples, event_times, look_back, look_ahead );
% 
%   all_samples(sample_types{i}) = mat;
% end
% 
% trials(event_name) = struct( 'samples', all_samples, 'time', t, 'sample_rate', fs );
% 
% end
% 
% function fs = get_sample_frequency(time)
% 
% fs = unique( diff(time(~isnan(time))) );
% 
% assert( numel(fs) == 1, 'Expected one unique inter-sample interval, but got %d', numel(fs) );
% 
% end
% 
% function [mat, t, fs] = get_aligned_samples(time, samples, events, look_back, look_ahead)
% 
% fs = get_sample_frequency( time );
% 
% start_ts = round( events + (look_back/fs) );
% amount = round( (look_ahead - look_back) / fs );
% 
% mat = nan( numel(start_ts), amount + 1 );
% 
% start_inds = shared_utils.sync.nearest( time, start_ts );
% is_valid_start = ~isnan( start_ts );
% 
% offsets = time(start_inds(is_valid_start)) - start_ts(is_valid_start);
% 
% assert( max(abs(offsets)) <= 1, ['Start time was more than 1 sample away from' ...
%   , ' a time sample in the raw .edf data.'] );
% 
% others = find( is_valid_start );
% 
% t = look_back:fs:look_back+round( amount*fs );
% 
% for i = 1:numel(others)
%   other = others(i);
%   start_ind = start_inds(other);
%   stop_ind = start_ind + amount;
%   
%   assign_start = 1;
%   assign_stop = size( mat, 2 );
%   
%   if ( stop_ind > numel(samples) )
%     assign_stop = assign_stop - (stop_ind - numel(samples) );
%     stop_ind = numel( samples );
%   end
%   
%   mat(other, assign_start:assign_stop) = samples(start_ind:stop_ind);
% end
% 
% end