function make_edfs(varargin)

conf = hwwa.config.load();
data_p = conf.PATHS.data_root;

defaults = hwwa.get_common_make_defaults();

input_p = hwwa.get_intermediate_dir( 'unified' );
output_p = hwwa.get_intermediate_dir( 'edf' );

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
  
  mat_ind = strfind( unified_filename, '.mat' );
  
  assert( ~isempty(mat_ind) && mat_ind > 1 ...
    , 'No ".mat" extension found in "%s".', unified_filename );
  
  edf_filename = [ unified_filename(1:mat_ind-1), '.edf' ];
  edf_fullfile = fullfile( data_p, unified.raw_subdir, edf_filename );
  
  if ( ~shared_utils.io.fexists(edf_fullfile) )
    fprintf( '\n edf file "%s" does not exist.', edf_filename );
    continue;
  end
  
  try
    edf_obj = Edf2Mat( edf_fullfile );
  catch err
    warning( err.message );
    continue;
  end
  
  edf = struct();
  samples = edf_obj.Samples;
  events = edf_obj.Events;
  
  edf.Samples = samples;
  edf.Events = events;
  edf.unified_filename = unified_filename;
  
  shared_utils.io.require_dir( output_p );
  
  save( output_filename, 'edf', '-v7.3' );
end

end