namespace :image_index do

	desc "index collection Image_Server_Image"
	task :image_server_image => :environment do 
  	image_indexes = ImageServerImage.collection.indexes.to_a

  	if !image_indexes.empty?
		  if !image_indexes.any?{|h| h[:name] === 'image_server_group_id_1'}
    		ImageServerImage.collection.indexes.create_one({'image_server_group_id':1})
  		end

		  if !image_indexes.any?{|h| h[:key].has_key?(:image_server_group_id) && h[:key].has_key?(:status)}
  	  	ImageServerImage.collection.indexes.create_one({'image_server_group_id':1, 'status':1})
	  	end

		  if !image_indexes.any?{|h| h[:key].has_key?(:image_server_group_id) && h[:key].has_key?(:difficulty)}
  	  	ImageServerImage.collection.indexes.create_one({'image_server_group_id':1, 'difficulty':1})
	  	end

		  if !image_indexes.any?{|h| h[:key].has_key?(:image_server_group_id) && h[:key].has_key?(:transcriber)}
	    	ImageServerImage.collection.indexes.create_one({'image_server_group_id':1, 'transcriber':1})
		  end

	  	if !image_indexes.any?{|h| h[:key].has_key?(:image_server_group_id) && h[:key].has_key?(:reviewer)}
    		ImageServerImage.collection.indexes.create_one({'image_server_group_id':1, 'reviewer':1})
		  end
		end
	end

	desc "index collection Source"
	task :source => :environment do
		source_indexes = Source.collection.indexes.to_a

		if !source_indexes.empty?
			if !source_indexes.any?{|h| h[:key].has_key?(:register_id) && h[:key].has_key?(:source_name)}
				Source.collection.indexes.create_one({'register_id':1, 'source_name':1})
			end
		end
	end

end