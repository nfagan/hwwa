bin = 10;
stp = 10;

behav_outputs = hwwa_load_basic_behav_measures( ...
    'files_containing', cellstr(hwwa.to_date(hwwa.get_learning_days())) ...
  , 'trial_bin_size', bin ...
  , 'trial_step_size', stp ...
  , 'is_parallel', true ...
);

%%

hwwa_plot_nondrug_learning( behav_outputs ...
  , 'do_save', true ...
  , 'base_subdir', sprintf('across_monks__bin_%d_stp_%d', bin, stp) ...
  , 'var_bin_size', 25 ...
  , 'var_step_size', 10 ...
  , 'per_monkey', false ...
);

%%

assert( bin == stp );

hwwa_run_plot_nondrug_cumulative_learning( behav_outputs );