function hwwa_plot_target_onset_heatmap(heat_maps, heat_map_labs, x, y, varargin)

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
defaults.before_plot_func = @(varargin) deal(varargin{1:nargout});
defaults.match_c_lims = true;
defaults.overlay_rects = [];
params = hwwa.parsestruct( defaults, varargin );

% per_image_cat( heat_maps, heat_map_labs', x, y, params );
across_image_cat( heat_maps, heat_map_labs', x, y, params );

end

function across_image_cat(heat_maps, heat_map_labs, x, y, params)

for i = 1:2
  subdir = 'across_image_category';
  
  if ( i == 2 )
    collapsecat( heat_map_labs, 'monkey' );
    subdir = sprintf( '%s-across_monkeys', subdir );
  else
    subdir = sprintf( '%s-per_monkey', subdir );
  end
  
  fcats = { 'monkey' };
  pcats = { 'trial_type', 'drug', 'monkey' };

  plot_heat_map( heat_maps, heat_map_labs, x, y, fcats, pcats, subdir, params );
end

end

function per_image_cat(heat_maps, heat_map_labs, x, y, params)

for i = 1:2
  subdir = 'per_image_category';
  
  if ( i == 2 )
    collapsecat( heat_map_labs, 'monkey' );
    subdir = sprintf( '%s-across_monkeys', subdir );
  else
    subdir = sprintf( '%s-per_monkey', subdir );
  end
  
  fcats = { 'monkey', 'target_image_category' };
  pcats = { 'trial_type', 'drug', 'monkey', 'target_image_category', 'scrambled_type' };

  plot_heat_map( heat_maps, heat_map_labs, x, y, fcats, pcats, subdir, params );
end

end

function r = rect_to_spectrogram_rect(rect, x, y)

nearest_x0 = nearest_bin( rect(1), x );
nearest_x1 = nearest_bin( rect(3), x );
nearest_y0 = nearest_bin( rect(2), y );
nearest_y1 = nearest_bin( rect(4), y );

x0 = to_bin_with_fraction( x, nearest_x0, rect(1) );
x1 = to_bin_with_fraction( x, nearest_x1, rect(3) );
y0 = to_bin_with_fraction( y, nearest_y0, rect(2) );
y1 = to_bin_with_fraction( y, nearest_y1, rect(4) );

r = [ x0, y0, x1, y1 ];

end

function r = transpose_rect(rect)

r = [ rect(2), rect(1), rect(4), rect(3) ];

end

function r = flip_rect_ud(rect, max_y)

r = [ rect(1), max_y - rect(2), rect(3), max_y - rect(4) ];

end

function adjusted_component = to_bin_with_fraction(bins, nearest_ind, component)

frac = (component - bins(nearest_ind)) / (bins(nearest_ind+1) - bins(nearest_ind));
adjusted_component = frac + nearest_ind;

end

function ind = nearest_bin(component, bins)

ind = find( bins > component, 1 ) - 1;

end

function plot_heat_map(heat_maps, heat_map_labs, x, y, fcats, pcats, subdir, params)

conf = params.config;
do_save = params.do_save;

spec = unique( cshorzcat(fcats, pcats) );

fig_I = findall_or_one( heat_map_labs, fcats );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_spectrogram( x, y );
  pl.smooth_func = @(x) imgaussfilt(x, 2);
  pl.add_smoothing = true;
  pl.match_c_lims = params.match_c_lims;
  pl.shape = [1, 2];

  plt = heat_maps(fig_I{i}, :, :);
  plt_labs = prune( heat_map_labs(fig_I{i}) );
  
  [plt, plt_labs] = params.before_plot_func( plt, plt_labs, spec );
  
  axs = pl.imagesc( plt, plt_labs, pcats );
  
  if ( ~isempty(params.overlay_rects) )
    for j = 1:numel(params.overlay_rects)
      rect = rect_to_spectrogram_rect( params.overlay_rects{j}, y, x );
      rect = flip_rect_ud( rect, numel(x) );
      hs = arrayfun( @(x) bfw.plot_rect_as_lines(x, rect), axs, 'un', 0 );
      cellfun( @(x) set(x, 'color', zeros(1, 3)), hs );
      cellfun( @(x) set(x, 'linewidth', 2), hs );
    end
  end
  
  if ( do_save )
    save_p = fullfile( hwwa.dataroot(conf), 'plots', 'approach_avoid' ...
      , 'behavior', hwwa.datedir, 'heat_map', params.base_subdir, subdir );
    
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, plt_labs, [fcats, pcats] );
  end
end

end