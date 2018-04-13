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
PATHS.data_root = '';
PATHS.repositories = '';

%   DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'shared_utils', 'eyelink', 'plexon', 'spike_helpers' };
DEPENDS.others = { '' };

%   PLEX
PLEX = struct();
PLEX.sync_channel = 'AI01';

%   EXPORT
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;
conf.PLEX = PLEX;

if ( do_save )
  hwwa.config.save( conf );
end

end