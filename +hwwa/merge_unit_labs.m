function data_labs = merge_unit_labs(data_labs, psth_labs)

import shared_utils.assertions.*;

assert__isa( data_labs, 'fcat', 'data labels' );
assert__isa( psth_labs, 'fcat', 'psth labels' );

n_units = numel( incat(psth_labs, 'id') );
data_sz = size( data_labs, 1 );
psth_sz = size( psth_labs, 1 );

assert( psth_sz == data_sz * n_units, 'PSTH size must be %d times data size.' ...
  , n_units );

repmat( data_labs, n_units );
prune( merge(data_labs, psth_labs) );

end

% psth_cats = getcats( psth_labs );
% addcat( data_labs, psth_cats );
% repmat( data_labs, n_units );
% 
% stp = 1;
% 
% for i = 1:n_units
%   ind = stp:stp+data_sz-1;
%   for j = 1:numel(psth_cats)
%     c = psth_cats{j};
%     setcat( data_labs, c, partcat(psth_labs, c, ind), ind );
%   end
%   stp = stp + data_sz;
% end
% 
% prune( data_labs );