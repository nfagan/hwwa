function hwwa_plot_drug_behav(rt, labels, varargin)

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
params = hwwa.parsestruct( defaults, varargin );

[rt, labels] = ensure_correct_subset( rt, labels' );

% Plot overall bars
run_plot_bar_percent_correct( rt, labels, params );
run_plot_bar_rt( rt, labels, params );

% Plot lines for each day
run_plot_percent_correct_per_day( rt, labels, params );
run_plot_rt_per_day( rt, labels, params );

end

function run_plot_percent_correct_per_day(data, labels, params)

spec = get_specificities();

for i = 1:numel(spec)
  plot_lines_per_day( data, labels', spec{i} ...
    , 'percent_correct_per_day', @get_p_correct_data, params );
end

end

function run_plot_rt_per_day(data, labels, params)

spec = get_specificities();

for i = 1:numel(spec)
  plot_lines_per_day( data, labels', spec{i} ...
    , 'rt_per_day', @get_rt_data, params );
end

end

function run_plot_bar_percent_correct(data, labels, params)

bar_specificities = get_specificities();

for i = 1:numel(bar_specificities)
  plot_bar_overall( data, labels', bar_specificities{i} ...
    , 'percent_correct', @get_p_correct_data, params );
end

end

function run_plot_bar_rt(data, labels, params)

bar_specificities = get_specificities();

for i = 1:numel(bar_specificities)
  plot_bar_overall( data, labels', bar_specificities{i} ...
    , 'rt', @get_rt_data, params );
end

end

function [rt, rt_labels] = get_rt_data(data, labels, rt_each, mask)

% Only correct go-trials
rt_mask = find( labels, {'go_trial', 'correct_true'}, mask );

% Calculate average rt for each `rt_each`
[rt_labels, I] = keepeach( labels', rt_each, rt_mask );
rt = rowop( data, I, @(x) nanmean(x, 1) );

end

function [pcorr, pcorr_labels] = get_p_correct_data(data, labels, data_each, mask)

% Calculate percent correct for each `p_each`
[pcorr, pcorr_labels] = hwwa.percent_correct( labels', data_each, mask );

end

function plot_lines_per_day(data, labels, specificity, measure_type, data_func, params)

mask = get_base_mask( labels );

handle_specificity( labels, specificity );

data_each = { 'date', 'target_image_category', 'trial_type' };

is_per_gender = ismember( 'gender', specificity ); 

if ( is_per_gender )
  data_each{end+1} = 'gender';
end

[plt_data, plt_labels] = data_func( data, labels, data_each, mask );

pl = plotlabeled.make_common();
pl.add_errors = false;
pl.per_panel_labels = true;
pl.x_order = { 'appetitive', 'threat', 'scrambled_appetitive' };

fig_cats = { 'monkey' };
xcats = { 'target_image_category' };
gcats = { 'day' };
pcats = { 'drug', 'trial_type', 'monkey', 'trial_type' };

if ( is_per_gender )
  xcats{end+1} = 'gender';
end

[figs, axs, fig_I] = pl.figures( @errorbar, plt_data, plt_labels, fig_cats, xcats, gcats, pcats );
shared_utils.plot.match_ylims( axs );

if ( params.do_save )
  base_p = fullfile( get_base_plot_path(params), measure_type );
  save_p = fullfile( base_p, make_specificity_subdir(specificity) );
  
  filename_cats = [ fig_cats, pcats ];
  
  save_figs( save_p, figs, fig_I, plt_labels, filename_cats );
end


end

function plot_bar_overall(data, labels, specificity, measure_type, data_func, params)

mask = get_base_mask( labels );

handle_specificity( labels, specificity );

data_each = { 'date', 'target_image_category', 'trial_type' };

is_per_gender = ismember( 'gender', specificity );

if ( is_per_gender )
  data_each{end+1} = 'gender';
end

[plt_data, plt_labels] = data_func( data, labels, data_each, mask );
hwwa.decompose_social_scrambled( plt_labels );

pl = plotlabeled.make_common();
pl.x_tick_rotation = 0;

fig_cats = { 'monkey' };
xcats = { 'target_image_category' };
gcats = { 'drug' };
pcats = { 'scrambled_type', 'trial_type', 'monkey' };

if ( is_per_gender )
  xcats{end+1} = 'gender';
end

[figs, axs, fig_I] = pl.figures( @bar, plt_data, plt_labels, fig_cats, xcats, gcats, pcats );

if ( params.do_save )
  base_p = fullfile( get_base_plot_path(params), measure_type );
  save_p = fullfile( base_p, make_specificity_subdir(specificity) );
  
  filename_cats = [ fig_cats, pcats ];
  
  save_figs( save_p, figs, fig_I, plt_labels, filename_cats );
end

end

function [rt, labels] = ensure_correct_subset(rt, labels)

assert_ispair( rt, labels );

days_5htp = hwwa.get_image_5htp_days();
days_sal = hwwa.get_image_saline_days();

use_days = unique( horzcat(days_5htp, days_sal) );

rt = indexpair( rt, labels, findor(labels, use_days) );
prune( labels );

end

function handle_specificity(labels, specificity)

if ( ~ismember('target_image_category', specificity) )
  collapsecat( labels, 'target_image_category' );
end

if ( ~ismember('monkey', specificity) )
  collapsecat( labels, 'monkey' );
end

end

function save_figs(save_p, figs, fig_I, labels, filename_cats)

for i = 1:numel(figs)
  f = figs(i);
  ind = fig_I{i};

  shared_utils.plot.fullscreen( f );

  dsp3.req_savefig( f, save_p, prune(labels(ind)), filename_cats );
end

end

function p = get_base_plot_path(params)

p = fullfile( hwwa.dataroot(params.config), 'plots', 'behavior' ...
  , hwwa.datedir, 'basic_behavior', params.base_subdir );

end

function mask = get_base_mask(labels)

mask = fcat.mask( labels ...
  , @find, {'initiated_true'} ...
  , @findnot, {'tar', '011619'} ...
  , @findnone, 'ephron' ...
  , @findnone, '021819' ... % Eliminate first saline day to match N.
);

end

function subdir = make_specificity_subdir(specificity)

subdir = '';

for i = 1:numel(specificity)
  format_str = ternary( i < numel(specificity), '%sper_%s__', '%sper_%s' );
  subdir = sprintf( format_str, subdir, specificity{i} );
end

if ( isempty(subdir) )
  subdir = 'across_all';
end

end

function specs = get_specificities()

specs = { ...
    {'target_image_category', 'monkey', 'gender'} ...
  , {'target_image_category', 'gender'} ...
  , {'target_image_category', 'monkey'} ...
  , {'target_image_category'} ...
};

end