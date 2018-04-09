function p = get_intermediate_dir(kind)

%   GET_INTERMEDIATE_DIR

if ( nargin == 0 )
  kind = '';
end

conf = hwwa.config.load();
p = fullfile( conf.PATHS.data_root, 'intermediates', kind );


end