function obj = get_looped_make_runner(params)

if ( nargin < 1 || isempty(params) )
  params = hwwa.get_common_make_defaults();
end

obj = shared_utils.pipeline.LoopedMakeRunner;
obj.save = params.save;
obj.is_parallel = params.is_parallel;
obj.overwrite = params.overwrite;
obj.filter_files_func = @(x) hwwa.files_containing( x, params.files_containing );
obj.get_identifier_func = @(x, y) x.unified_filename;
obj.log_level = params.log_level;

end