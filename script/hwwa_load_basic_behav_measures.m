function outs = hwwa_load_basic_behav_measures(varargin)

defaults = hwwa.get_common_make_defaults();
defaults.time_trial_bin_size = 15*60; % 15 minutes
defaults.trial_bin_size = 50;
defaults.trial_step_size = 1;

inputs = { 'trial_data', 'meta', 'labels', 'events' };
output = '';

[params, loop_runner] = hwwa.get_params_and_loop_runner( inputs, output ...
  , defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

results = loop_runner.run( @main, params );
results(~[results.success]) = [];

outputs = [results.output];
outs = struct();

if ( isempty(outputs) )
  outs.rt = [];
  outs.labels = fcat();
else
  match_categories( outputs );
  
  outs.rt = vertcat( outputs.rt );
  outs.labels = vertcat( fcat(), outputs.labels );
end

end

function out = main(files, params)

trial_data_file = shared_utils.general.get( files, 'trial_data' );
meta_file = shared_utils.general.get( files, 'meta' );
labels_file = shared_utils.general.get( files, 'labels' );
events_file = shared_utils.general.get( files, 'events' );

rt = reshape( [trial_data_file.trial_data(:).reaction_time], [], 1 );

trial_start_times = events_file.event_times(:, events_file.event_key('new_trial'));
time_trial_bin_size = params.time_trial_bin_size;
trial_bin_size = params.trial_bin_size;
trial_step_size = params.trial_step_size;

labs = labels_file.labels';

hwwa.add_day_labels( labs );
hwwa.add_data_set_labels( labs );
% hwwa.add_drug_labels( labs );
hwwa.add_drug_labels_by_day( labs );
hwwa.fix_image_category_labels( labs );
hwwa.add_time_bin_labels( labs, trial_start_times, time_trial_bin_size );
hwwa.add_trial_bin_labels( labs, trial_bin_size, trial_step_size );
hwwa.split_gender_expression( labs );

addcat( labs, 'monkey' );
setcat( labs, 'monkey', lower(meta_file.monkey) );

prune( labs );

out = struct();
out.rt = rt;
out.labels = labs;

end

function match_categories(outputs)

cats = containers.Map();

for i = 1:numel(outputs)
  c = getcats( outputs(i).labels );
  
  for j = 1:numel(c)
    cats(c{j}) = 1;
  end
end

cats = keys( cats );

for i = 1:numel(outputs)
  addcat( outputs(i).labels, cats );
end

end