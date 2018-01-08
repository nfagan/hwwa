function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

if ( nargin < 1 ), do_save = false; end

const = hwwa.config.constants();

conf = struct();

%   ID
conf.(const.config_id) = true;

%   PATHS
PATHS = struct();
PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/hww_gng/data';

%   EXPORT
conf.PATHS = PATHS;

if ( do_save )
  hwwa.config.save( conf );
end

end