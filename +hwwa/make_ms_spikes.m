function make_ms_spikes(varargin)

defaults = hwwa.get_common_make_defaults();

params = hwwa.parsestruct( defaults, varargin );

conf = hwwa.config.load();

firings_p = fullfile( conf.PATHS.data_root, 'ms', 'firings' );
meta_p = fullfile( conf.PATHS.data_root, 'ms', 'meta' );

files = params.files;
fc = params.files_containing;

mda_files = hwwa.require_intermediate_mats( files, firings_p, fc, '.mda' );

for i = 1:numel(mda_files)
  hwwa.progress( i, numel(mda_files), mfilename );
  
  [~, meta_id] = fileparts( mda_files{i} );
  
  firings = readmda( mda_files{i} );
  meta_file = shared_utils.io.fload( fullfile(meta_p, sprintf('%s.mat', meta_id)) );
  
  un_id = meta_file.unified_id;
  t = meta_file.time;
  
  ms_channel_ids = firings(1, :);
  ms_spike_times = firings(2, :);
  ms_unit_ids = firings(3, :);
  
  first_unit = true;
  
  for j = 1:numel(ms_channel_ids)
    
    ms_channel_id = ms_channel_ids(j);
    
    channel_ind = ms_channel_ids == ms_channel_id;
    
%     channel_name = meta_fi
    
    unit_ns = unique( ms_unit_ids(channel_ind) );
    
    for k = 1:numel(unit_ns)
      
      unit_n = unit_ns(k);
      unit_ind = channel_ind & ms_unit_ids == unit_n;
      spike_ts = t(ms_spike_times(unit_ind));
      
      unit = struct();
      unit.times = spike_ts;
      unit.channel = channel_name;
      unit.number = unit;
      unit.id = sprintf( '%s-%s-%d', un_id, channel_name, k );
      
      if ( first_unit )
        all_units = unit;
        first_unit = false;
      else
        all_units = [ all_units; unit ];
      end
      
    end
    
  end
end

end