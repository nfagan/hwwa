function defaults = get_common_make_defaults( assign_to )

if ( nargin == 0 )
  defaults = struct();
else
  defaults = assign_to;
end

defaults.files = [];
defaults.files_containing = [];
defaults.overwrite = false;
defaults.append = true;
defaults.save = true;
defaults.config = hwwa.config.load();

end