function make_unified(varargin)

defaults = hwwa.get_common_make_defaults();

raw_subdir = 'raw_redux';

conf = hwwa.config.load();
input_p = fullfile( conf.PATHS.data_root, raw_subdir );
output_p = hwwa.get_intermediate_dir( 'unified' );

params = hwwa.parsestruct( defaults, varargin );

mats = hwwa.require_intermediate_mats( params.files, input_p, params.files_containing );

for i = 1:numel(mats)
  hwwa.progress( i, numel(mats), mfilename );
  
  [~, unified_id] = fileparts( mats{i} );
  unified_filename = [ unified_id, '.mat' ];
  
  output_filename = fullfile( output_p, unified_filename );
  
  if ( hwwa.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  raw = shared_utils.io.fload( mats{i} );
  
  raw_data = errors_to_string( raw.DATA );
  
  raw.DATA = raw_data;
  raw.unified_filename = unified_filename;
  raw.unified_id = unified_id;
  raw.raw_subdir = raw_subdir;
  
  shared_utils.io.require_dir( output_p );
  
  save( output_filename, 'raw' );
end

end

function s = errors_to_string(s)

fields = fieldnames( s );

error_prefix = 'error__';

errs = find( cellfun(@(x) ~isempty(strfind(x, error_prefix)), fields) );

for idx = 1:numel(s)

  str = '';

  for i = 1:numel(errs)
    f = fields{errs(i)};
    val = s(idx).(f);

    if ( val )
      assert( isempty(str), 'More than one error for this trial.' );
      str = f(numel(error_prefix)+1:end);
    end
  end

  if ( isempty(str) )
    str = 'no_errors';
  end

  s(idx).error = str;
end

s = rmfield( s, fields(errs) );

end