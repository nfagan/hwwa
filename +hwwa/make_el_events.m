function [results, params] = make_el_events(varargin)

defaults = hwwa.get_common_make_defaults();

inputs = { 'events', 'edf' };
output = 'el_events';

[params, loop_runner] = hwwa.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @hwwa.make.el_events );

end