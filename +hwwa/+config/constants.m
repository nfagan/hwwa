function const = constants()

const = struct();

config_folder = fileparts( which(sprintf('hwwa.config.%s', mfilename)) );

const.config_filename = 'config.mat';
const.config_id = 'HWWA__IS_CONFIG__';
const.config_folder = config_folder;

end