function labs = add_data_set_labels(labs)

addcat( labs, 'data_set' );

ro1_days = { '050818', '050918', '051018', '051118', '051418' };
tarantino_check_days = { '100118', '100218', '100318', '100418' };
tarantino_check_drug_days = { '101118', '101218', '101518', '101718' ...
  , '102218', '102318' '102418', '102518' };

add_days( labs, ro1_days, 'ro1' );
add_days( labs, tarantino_check_days, 'tarantino_delay_check' );
add_days( labs, tarantino_check_drug_days, 'tarantino_drug_check' );

end

function add_days(labs, days, lab)

for i = 1:numel(days)
  setcat( labs, 'data_set', lab, find(labs, days{i}) );
end

end