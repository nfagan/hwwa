function hwwa_plot_learning_running_p_correct(rt, labels, varargin)

defaults = struct();
defaults.config = hwwa.config.load();
defaults.trial_bin_size = 1;
defaults.trial_step_size = 1;
defaults.use_cumulative = true;
defaults.is_per_image_category = true;
defaults.is_per_monkey = true;
defaults.base_subdir = '';
defaults.base_prefix = '';
defaults.do_save = false;
defaults.colored_lines_are = 'day';
defaults.combine_days = false;
defaults.is_rt = false;
defaults.rt_func = @default_cumulative_rt_mean_func;
defaults.line_ylims = [];
defaults.line_xlims = [];

params = hwwa.parsestruct( defaults, varargin );

conf = params.config;

date_dir = datestr( now, 'mmddyy' );
plot_p = fullfile( conf.PATHS.data_root, 'plots', 'behavior', date_dir, 'cumulative_learning' );
plot_p = fullfile( plot_p, ternary(params.is_rt, 'rt', 'percent_correct') );

if ( params.is_rt )
  mask = fcat.mask( labels ...
    , @find, {'pilot_social', 'initiated_true', 'correct_true', 'go_trial'} ...
    , @findnot, {'tar', '011619'} ...
  );
else
  mask = fcat.mask( labels ...
    , @find, {'pilot_social', 'initiated_true', 'no_errors', 'wrong_go_nogo'} ...
    , @findnot, {'tar', '011619'} ...
  );
end

pcorr_spec = { 'trial_type', 'date' };

if ( params.is_per_image_category )
  pcorr_spec{end+1} = 'target_image_category';
end

if ( params.combine_days )  
  [labels, combined_I] = combine_days( labels, 'monkey', mask );
  
  mask = rowmask( labels );
  
  if ( ~params.is_per_monkey )
    setcat( labels, 'day', 'day_1' );
  end
  
  if ( params.is_rt )
    rt = rt(combined_I);
  end
end

if ( params.is_rt )
  [pcorr_dat, pcorr_labs] = hwwa.running_calculation( rt, labels', pcorr_spec, params.rt_func ...
    , 'mask', mask ...
    , 'trial_bin_size', params.trial_bin_size ...
    , 'trial_step_size', params.trial_step_size ...
    , 'use_cumulative', params.use_cumulative ...
  );
else
  [pcorr_dat, pcorr_labs] = hwwa_running_p_correct( labels', pcorr_spec ...
    , 'mask', mask ...
    , 'trial_bin_size', params.trial_bin_size ...
    , 'trial_step_size', params.trial_step_size ...
    , 'use_cumulative', params.use_cumulative ...
  );  
end

%%

plot_auc( pcorr_dat, pcorr_labs', plot_p, params );

% plot_per_day_lines_go_nogo( pcorr_dat, pcorr_labs', plot_p, params );
plot_per_day_colored_lines( pcorr_dat, pcorr_labs', plot_p, params );

end

function [new_labs, orig_ind] = combine_days(labs, within, mask)

I = findall_or_one( labs, within, mask );

new_labs = fcat();

ind = cell( numel(I), 1 );

for i = 1:numel(I)
  [one_new_labs, ordered_I] = one_combine_days( labs, I{i}, i );
  
  append( new_labs, one_new_labs );
  ind{i} = ordered_I;
end

prune( new_labs );

orig_ind = vertcat( ind{:} );

end

function [new_labs, ordered_I] = one_combine_days(labs, mask, date_number)

[I, dates] = findall( labs, 'date', mask );
[~, order] = sort( datenum(dates) );

ordered_I = vertcat( I{order} );

new_labs = labs(ordered_I);

original_dates = cellstr( new_labs, 'date' );

setcat( new_labs, 'date', sprintf( 'date_%d', date_number) );
setcat( new_labs, 'day', sprintf( 'day_%d', date_number) );

prune( new_labs );

addsetcat( new_labs, 'original_date', original_dates );

end

function [pcorr_dat, pcorr_labs] = scrambled_minus_social(pcorr_dat, pcorr_labs)

%%

spec = { 'date', 'target_image_category', 'trial_type' };

sub_cat = whichcat( pcorr_labs, 'scrambled' );

a = 'scrambled';
b = 'not-scrambled';

[pcorr_dat, pcorr_labs] = dsp3.summary_binary_op( ...
  pcorr_dat, pcorr_labs', spec, a, b, @minus, @(x) nanmean(x, 1) );

setcat( pcorr_labs, sub_cat, sprintf('%s-%s', a, b) );

end

function aucs = get_auc(pcorr_dat)

aucs = rownan( rows(pcorr_dat) );

for i = 1:rows(pcorr_dat)
  row = pcorr_dat(i, :);
  row = row(~isnan(row));
  
  aucs(i) = trapz( row );
end

end

function plot_auc(pcorr_dat, pcorr_labs, plot_p, params)

if ( ~strcmp(params.colored_lines_are, 'day') )
  hwwa.decompose_social_scrambled( pcorr_labs );
end

[fcats, gcats, pcats, xcats] = get_bar_plot_categories( params.colored_lines_are );

spec = unique( cshorzcat(fcats, gcats, pcats, xcats) );

[~, I] = keepeach( pcorr_labs, spec );
aucs = get_auc( bfw.row_nanmean(pcorr_dat, I) );

if ( strcmp(params.colored_lines_are, 'scrambled_minus_social') )
  [aucs, pcorr_labs] = scrambled_minus_social( aucs, pcorr_labs' );
end

pl = plotlabeled.make_common();

if ( ~params.is_per_monkey )
  collapsecat( pcorr_labs, 'monkey' );
end

[figs, axs, I] = pl.figures( @bar, aucs, pcorr_labs, fcats, xcats, gcats, pcats );

shared_utils.plot.match_ylims( axs );

if ( params.do_save )
  for i = 1:numel(figs)
    dsp3.req_savefig( figs(i), fullfile(plot_p, params.base_subdir), pcorr_labs(I{i}) ...
      , unique(cshorzcat(pcats, fcats)) ...
      , sprintf('auc_%s', params.base_prefix) );
  end
end

end

function plot_per_day_colored_lines(pcorr_dat, pcorr_labs, plot_p, params)

plot_subdir = params.base_subdir;
base_prefix = params.base_prefix;
do_save = params.do_save;

min_y = 0;

if ( ~strcmp(params.colored_lines_are, 'day') )
  hwwa.decompose_social_scrambled( pcorr_labs );
end

if ( strcmp(params.colored_lines_are, 'scrambled_minus_social') )
  [pcorr_dat, pcorr_labs] = scrambled_minus_social( pcorr_dat, pcorr_labs );
  min_y = -1;
end

[fcats, gcats, pcats] = get_line_plot_categories( params.colored_lines_are );

if ( ~params.is_per_monkey )
  collapsecat( pcorr_labs, 'monkey' );
end

pl = plotlabeled.make_common();
pl.one_legend = false;
pl.panel_order = { 'appetitive', 'threat', 'scrambled appetitive' };

if ( isempty(params.line_ylims) )
  pl.y_lims = [min_y, 1];
else
  pl.y_lims = params.line_ylims;
end

pl.summary_func = @(x) nanmedian(x, 1);
pl.add_x_tick_labels = false;
pl.add_errors = false;

[figs, axs, I, ax_I] = pl.figures( @lines, pcorr_dat, pcorr_labs, fcats, gcats, pcats );

for i = 1:numel(figs)
  f_axs = findobj( figs(i), 'type', 'axes' );
  
  line_handles = findobj( f_axs, 'type', 'line' );
  
  set_line_colors( line_handles );
end

if ( do_save )
  for i = 1:numel(figs)
    is_subset_ax = ax_I == i;
    
    shared_utils.plot.match_xlims( axs(is_subset_ax) );
    
    if ( ~isempty(params.line_xlims) )
      shared_utils.plot.set_xlims( axs(is_subset_ax), params.line_xlims );
    end
    
    dsp3.req_savefig( figs(i), fullfile(plot_p, plot_subdir), pcorr_labs(I{i}) ...
      , unique(cshorzcat(pcats, fcats)) ...
      , sprintf('percent_correct_%s', base_prefix) );
  end
end

end

function set_line_colors(line_handles)

line_labels = { line_handles.DisplayName };

assert( ~any(cellfun(@isempty, line_labels)), 'Missing line display name.' );

dates_trials = cellfun( @(x) strsplit(x, ' | '), line_labels, 'un', 0 );
dates = cellfun( @(x) x{1}, dates_trials, 'un', 0 );

unique_dates = unique( dates );
unique_trials = {};

if ( ~isempty(dates_trials) && numel(dates_trials{1}) > 1 )
  trials = cellfun( @(x) strjoin(x(2:end), '_'), dates_trials, 'un', 0 );
  unique_trials = unique( trials );
end

n_trials = numel( unique_trials );
n_dates = numel( unique_dates );

color_funcs = { @cool, @autumn };

if ( n_trials == 0 )
  use_complete_true = true;
  n_trials = 1;
else
  use_complete_true = false;
end

for i = 1:n_trials
  
  if ( use_complete_true )
    matches_trial = true( size(dates) );
  else
    matches_trial = strcmp( trials, unique_trials{i} );
  end
  
  color_func_ind = min( i, numel(color_funcs) );
  
  color_map = color_funcs{color_func_ind}(n_dates);
  
  for j = 1:n_dates
    matches_date = find( strcmp(dates, unique_dates{j} ) & matches_trial );
    
    for k = 1:numel(matches_date)
      line_handles(matches_date(k)).Color = color_map(j, :);
    end
  end
end

end

function plot_per_day_lines_go_nogo(pcorr_dat, pcorr_labs, plot_p, params)

plot_subdir = params.base_subdir;
base_prefix = params.base_prefix;

do_save = params.do_save;
is_per_day = true;

if ( ~is_per_day )
  collapsecat( pcorr_labs, 'day' );
end

fcats = { 'monkey', 'day' };
gcats = { 'trial_type' };
pcats = { 'monkey', 'day', 'target_image_category' };

pl = plotlabeled.make_common();

pl.y_lims = [0, 1];
pl.summary_func = @(x) nanmedian(x, 1);
pl.add_x_tick_labels = false;
pl.add_errors = false;

[figs, axs, I] = pl.figures( @lines, pcorr_dat, pcorr_labs, fcats, gcats, pcats );

if ( do_save )
  for i = 1:numel(figs)
    dsp3.req_savefig( figs(i), fullfile(plot_p, plot_subdir), pcorr_labs(I{i}) ...
      , unique(cshorzcat(pcats, fcats)) ...
      , sprintf('percent_correct_%s', base_prefix) );
  end
end

end

function [fcats, gcats, pcats, xcats] = get_bar_plot_categories(colored_lines_are)

switch ( colored_lines_are )    
  case 'social_vs_scrambled'
    xcats = { 'target_image_category' };
    gcats = { 'trial_type' };
    pcats = { 'monkey', 'day', 'scrambled_type' };
    fcats = { 'monkey' };
    
  case 'scrambled_minus_social'
    xcats = { 'target_image_category' };
    gcats = { 'trial_type' };
    pcats = { 'monkey', 'day', 'scrambled_type' }; 
    fcats = { 'monkey' };
    
  case 'threat_vs_appetitive'
    xcats = { 'scrambled_type' };
    gcats = { 'trial_type' };
    pcats = { 'monkey', 'day', 'target_image_category' }; 
    fcats = { 'monkey' };
    
  otherwise
    error( 'Unrecognized line type: "%s".', colored_lines_are );
end

end

function [fcats, gcats, pcats] = get_line_plot_categories(colored_lines_are)

switch ( colored_lines_are )
  case 'day'
    fcats = { 'monkey', 'trial_type' };
    gcats = { 'day' };
    pcats = { 'monkey', 'target_image_category', 'trial_type' };
    
  case 'social_vs_scrambled'    
    fcats = { 'monkey', 'day' };
    gcats = { 'target_image_category' };
    pcats = { 'monkey', 'day', 'scrambled_type', 'trial_type' };
    
  case 'scrambled_minus_social'
    gcats = { 'target_image_category' };
    fcats = { 'monkey', 'day' };
    pcats = { 'monkey', 'day', 'scrambled_type', 'trial_type' };    
    
  case 'threat_vs_appetitive'    
    fcats = { 'monkey', 'day' };
    gcats = { 'scrambled_type' };
    pcats = { 'monkey', 'day', 'target_image_category', 'trial_type' };
    
  otherwise
    error( 'Unrecognized line type: "%s".', params.colored_lines_are );
end

end

function v = default_cumulative_rt_mean_func(prev, data, I)

new_mean = nanmean( data(I) );
v = nanmean( [prev(:); new_mean] );

end