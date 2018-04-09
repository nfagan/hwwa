function add_depends()

conf = hwwa.config.load();

repos = conf.DEPENDS.repositories;
repo_p = conf.PATHS.repositories;

for i = 1:numel(repos)
  addpath( genpath(fullfile(repo_p, repos{i})) );
end

end