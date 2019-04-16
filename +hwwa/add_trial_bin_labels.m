function labs = add_trial_bin_labels(labs, bin_size, step_size)

max_rows = rows( labs );
start = 1;
stop = min( max_rows, bin_size );
bin_idx = 1;

addcat( labs, 'trial_bin' );

while ( stop <= max_rows )
  ind = start:stop;
  
  setcat( labs, 'trial_bin', sprintf('trial_bin__%d', bin_idx), ind );
  
  if ( stop == max_rows )
    break;
  end
  
  start = start + step_size;
  stop = min( start + bin_size - 1, max_rows );
  
  bin_idx = bin_idx + 1;
end

end