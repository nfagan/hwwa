function p = get_intermediate_dir(kind, conf)

%   GET_INTERMEDIATE_DIR

if ( nargin < 1 ), kind = ''; end
if ( nargin < 2 || isempty(conf) )
  conf = hwwa.config.load();
else
  hwwa.util.assertions.assert__is_config( conf );
end

p = fullfile( conf.PATHS.data_root, 'intermediates', kind );


end