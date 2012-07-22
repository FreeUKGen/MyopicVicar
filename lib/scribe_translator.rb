module ScribeTranslator

  def self.image_file_to_asset(image_file, asset_collection)
    Asset.create({
      :ext_ref => File.basename(image_file.name),
      :location => image_file.image_url,
      :display_width => 1200,
      :height => image_file.height,
      :width => image_file.width,
      :template => Template.find(asset_collection.template),
      :asset_collection => asset_collection,
      :thumbnail_location => image_file.thumbnail_url,
      :thumbnail_width => image_file.thumbnail_width,
      :thumbnail_height => image_file.thumbnail_height        
    })
  end

  def self.image_list_to_asset_collection(image_list)
    ac = AssetCollection.create({
      :title => image_list.name, 
      :chapman_code => image_list.chapman_code, 
      :start_date => image_list.start_date, 
      :end_date => image_list.end_date, 
      :template => image_list.template, 
      :difficulty => image_list.difficulty,
      :has_thumbnails => true,
      :median_thumb_width => median_thumb_width(image_list)})
      
    image_list.image_files.each do |f|
      image_file_to_asset(f, ac)
    end
    ac
  end

  def self.median_thumb_width(image_list)
    widths = image_list.image_files.map { |f| f.thumbnail_width }
    middle = widths.length / 2
    # return the median width
    widths.sort.at(middle)
  end


end