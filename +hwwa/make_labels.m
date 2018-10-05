function make_labels(varargin)

defaults = hwwa.get_common_make_defaults();
params = hwwa.parsestruct( defaults, varargin );

conf = params.config;

input_p = hwwa.get_intermediate_dir( 'unified', conf );
output_p = hwwa.get_intermediate_dir( 'labels', conf );

mats = hwwa.require_intermediate_mats( params.files, input_p, params.files_containing );

reprocess_fields = { 'cue_delay', 'trial_number', 'trial_outcome', 'trial_type' };
ignore_fields = [ {'reaction_time', 'events', 'target_displacement', 'reward'}, reprocess_fields ];

for i = 1:numel(mats)
  hwwa.progress( i, numel(mats), mfilename );
  
  unified = shared_utils.io.fload( mats{i} );
  unified_filename = unified.unified_filename;
  output_filename = fullfile( output_p, unified_filename );
  
  if ( hwwa.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    data = unified.DATA;

    str_delays = num_field_to_str( data, 'cue_delay', 'delay__' );
    str_trials = num_field_to_str( data, 'trial_number', 'trial__' );

    all_fields = fieldnames( data );
    use_fields = setdiff( all_fields, ignore_fields );

    f = addcat( fcat(), [use_fields(:)', reprocess_fields] );

    for j = 1:numel(use_fields)
      field = use_fields{j};
      setcat( f, field, {data(:).(field)} );
    end

    setcat( f, 'cue_delay', str_delays );
    setcat( f, 'trial_number', str_trials );
  
    trial_outs = { data(:).trial_outcome };
    trial_types = { data(:).trial_type };

    empty_outs = cellfun( @isempty, trial_outs );
    trial_outs(empty_outs) = { 'no' };

    trial_outs = cellfun( @(x) [x, '_choice'], trial_outs, 'un', false );
    trial_types = cellfun( @(x) [x, '_trial'], trial_types, 'un', false );

    setcat( f, 'trial_outcome', trial_outs );
    setcat( f, 'trial_type', trial_types );

    %
    %   date info
    %

    addcat( f, {'date', 'drug', 'unified_filename'} );
    setcat( f, 'date', unified.date );
    setcat( f, 'unified_filename', unified_filename );

    %
    %   derived labels
    %

    hwwa.add_correct_labels( f );
    hwwa.add_prev_trial_correct_labels( f );
    hwwa.add_initiated_labels( f );
    hwwa.add_drug_labels( f );
    hwwa.add_trial_type_change_labels( f );

    labels = struct();
    labels.labels = f;
    labels.unified_filename = unified_filename;
    
  catch err
    warning( '"%s failed: %s".', unified_filename, err.message );
    continue;
  end
  
  shared_utils.io.require_dir( output_p );
  
  save( output_filename, 'labels' );
end

end

function out = num_field_to_str(data, fieldname, prefix)
out = arrayfun( @(x) [prefix, num2str(x.(fieldname))], data, 'un', false );
end