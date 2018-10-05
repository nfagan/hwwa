function labs = add_data_set_labels(labs)

addcat( labs, 'data_set' );

ro1_days = { '050818', '050918', '051018', '051118', '051418' };
tarantino_check_days = { '100118', '100218', '100318', '100418' };

add_days( labs, ro1_days, 'ro1' );
add_days( labs, tarantino_check_days, 'tarantino_delay_check' );

end

function add_days(labs, days, lab)

for i = 1:numel(days)
  ind = find( labs, days{i} );

  if ( isempty(ind) )
    continue;
  end

  setcat( labs, 'data_set', lab, ind );
end

end