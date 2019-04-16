function decompose_social_scrambled(labs)

image_categories = combs( labs, 'target_image_category' );

addsetcat( labs, 'scrambled_type', 'not-scrambled' );

for i = 1:numel(image_categories)
  image_category = image_categories{i};
  is_lab = find( labs, image_category );
  
  scrambled_ind = strfind( image_category, 'scrambled_' );
  
  if ( ~isempty(scrambled_ind) )
    sans_scrambled = strrep( image_category, 'scrambled_', '' );
    
    replace( labs, image_category, sans_scrambled );
    
    setcat( labs, 'scrambled_type', 'scrambled', is_lab );
  end
end

end
