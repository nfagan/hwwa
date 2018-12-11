function defaults = unified(varargin)

defaults = hwwa.get_common_make_defaults( varargin{:} );
defaults.raw_subdirectory = 'raw_redux';

end