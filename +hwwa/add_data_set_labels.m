function labs = add_data_set_labels(labs)

addcat( labs, 'data_set' );

ro1_days = { '050818', '050918', '051018', '051118', '051418' };

for i = 1:numel(ro1_days)
  ind = find( labs, ro1_days{i} );

  if ( isempty(ind) )
    continue;
  end

  setcat( labs, 'data_set', 'ro1', ind );
end

end