function [results, params] = make_unified(varargin)

defaults = hwwa.make.defaults.unified();

params = hwwa.parsestruct( defaults, varargin );

raw_subdir = 'raw_redux';
conf = params.config;

% input directory is the 'raw_redux' subfolder of the root data directory
inputs = fullfile( hwwa.dataroot(conf), raw_subdir );

% output directory is the 'unified' subfolder of the intermediates
% directory.
output = hwwa.get_intermediate_dir( 'unified', conf );

loop_runner = hwwa.get_looped_make_runner( params );

loop_runner.input_directories = inputs;
loop_runner.output_directory = output;
loop_runner.get_identifier_func = @get_unified_filename;
loop_runner.call_with_identifier = true;
loop_runner.func_name = mfilename;

results = loop_runner.run( @hwwa.make.unified );

end

function un_filename = get_unified_filename(varargin)

un_filename = shared_utils.io.filenames( varargin{2} );
un_filename = shared_utils.char.require_end( un_filename, '.mat' );

end