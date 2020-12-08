function hwwa_overall_p_correct(labels, varargin)

defaults = hwwa.get_common_plot_defaults( hwwa.get_common_make_defaults() );
defaults.mask_func = @hwwa.default_mask_func;
defaults.pcorr_each = { 'unified_filename', 'monkey', 'drug', 'trial_type', 'scrambled_type' };
defaults.anova_factors = [];
defaults.per_target_image_category = false;
defaults.per_drug = true;
params = hwwa.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

pcorr_each = get_pcorr_each( params );
[pcorr, pcorr_labels] = hwwa.percent_correct( labels', pcorr_each, mask );

norm_each = setdiff( pcorr_each, {'unified_filename'} );
[norm_corr, norm_labels] = hwwa.saline_normalize( pcorr, pcorr_labels', norm_each );

%%  raw
% anovas_each = { 'trial_type' };
anovas_each = {};
anova_factors = setdiff( pcorr_each, {'unified_filename'} );
anova_factors = setdiff( anova_factors, anovas_each );

if ( ~isempty(params.anova_factors) && iscell(params.anova_factors) )
  anova_factors = params.anova_factors;
end

v_gcats = { 'scrambled_type', 'target_image_category' };
v_pcats = { 'trial_type' };
run_violin( pcorr, pcorr_labels', v_gcats, v_pcats, 'raw', params );


run_anova( pcorr, pcorr_labels', anovas_each, anova_factors, 'raw', params );

%%  normalized

norm_subdir = 'normalized';

norm_anovas_each = {};
norm_anova_factors = setdiff( norm_each, {'unified_filename', 'drug', 'monkey'} );
norm_anova_factors = setdiff( norm_anova_factors, norm_anovas_each );

run_anova( norm_corr, norm_labels', norm_anovas_each, norm_anova_factors, norm_subdir, params );

norm_ts_each = { 'trial_type' };
norm_ta = { 'scrambled' };
norm_tb = { 'not-scrambled' };
run_ttests( norm_corr, norm_labels', norm_ts_each, norm_ta, norm_tb, norm_subdir, params );

norm_sr_each = { 'trial_type', 'scrambled_type' };
run_signrank1( norm_corr, norm_labels', norm_sr_each, norm_subdir, params );

end

function run_signrank1(data, labels, each, subdir, params)

sr_outs = dsp3.signrank1( data, labels', each ...
  , 'signrank_inputs', {1} ...
);

maybe_save_sr_outs( sr_outs, each, subdir, params );

end

function run_ttests(data, labels, each, a, b, subdir, params)

ttest_outs = dsp3.ttest2( data, labels', each, a, b );
maybe_save_ttest_outs( ttest_outs, each, subdir, params );

end

function run_anova(data, labels, each, factors, subdir, params)

anova_outs = dsp3.anovan( data, labels', each, factors ...
  , 'dimension', 1:numel(factors) ...
  , 'remove_nonsignificant_comparisons', false ...
);

maybe_save_anova_outs( anova_outs, [each, factors], subdir, params );

end

function run_violin(data, labels, gcats, pcats, subdir, params)

%%

pl = plotlabeled.make_common();

axs = pl.violinalt( data, labels, gcats, pcats );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  shared_utils.plot.match_ylims( axs );
  save_p = hwwa.approach_avoid_data_path( params, 'plots', 'pcorr', subdir, 'violin' );
  dsp3.req_savefig( gcf, save_p, labels, [gcats, pcats], params.prefix );
end

end

function maybe_save_ttest_outs(ttest_outs, spec, subdir, params)

if ( params.do_save )
  save_p = hwwa.approach_avoid_data_path( params, 'analyses', 'pcorr', subdir );
  dsp3.save_ttest2_outputs( ttest_outs, save_p, spec );
end

end

function maybe_save_anova_outs(anova_outs, spec, subdir, params)

if ( params.do_save )
  save_p = hwwa.approach_avoid_data_path( params, 'analyses', 'pcorr', subdir );
  dsp3.save_anova_outputs( anova_outs, save_p, spec );
end

end

function maybe_save_sr_outs(sr_outs, spec, subdir, params)

if ( params.do_save )
  save_p = hwwa.approach_avoid_data_path( params, 'analyses', 'pcorr', subdir );
  dsp3.save_signrank1_outputs( sr_outs, save_p, spec );
end

end

function each = get_pcorr_each(params)

each = params.pcorr_each;

if ( params.per_target_image_category )
  each{end+1} = 'target_image_category';
end
if ( ~params.per_drug )
  each = setdiff( each, {'drug'} );
end

end

function each = percent_correct_each()

each = { 'unified_filename', 'monkey', 'drug', 'trial_type', 'scrambled_type' };

end

function mask = get_base_mask(labels, mask_func)

mask = mask_func( labels, hwwa.get_approach_avoid_mask(labels) );

end