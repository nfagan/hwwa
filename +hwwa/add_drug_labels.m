function labs = add_drug_labels(labs)

import shared_utils.assertions.*;

assert__isa( labs, 'fcat', 'labels' );

saline_days = { '0215', '0221', '0228', '0302', '0303', '0305' };
serotonin_days = { '0214', '0216', '0220', '0222', '0301', '0304' };

for i = 1:numel(saline_days)
  ind = find( labs, [ saline_days{i}, '.mat' ] );
  if ( isempty(ind) ), continue; end
  labs(ind, 'drug') = 'saline';
end
for i = 1:numel(serotonin_days)
  ind = find( labs, [ serotonin_days{i}, '.mat' ] );
  if ( isempty(ind) ), continue; end
  labs(ind, 'drug') = '5-htp';
end

end