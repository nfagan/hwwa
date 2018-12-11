function p = dataroot(conf)

if ( nargin < 1 || isempty(conf) )
  conf = hwwa.config.load();
else
  hwwa.util.assertions.assert__is_config( conf );
end

p = conf.PATHS.data_root;

end