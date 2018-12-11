function [result, params] = make_alternate_el_events(varargin)

defaults = hwwa.get_common_make_defaults();

inputs = { 'events', 'edf' };
output = 'edf_events';

[params, loop_runner] = hwwa.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

result = loop_runner.run( @hwwa.make.alternate_el_events );

end