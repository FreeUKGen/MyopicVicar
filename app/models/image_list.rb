require 'chapman_code'
class ImageList 
  include MongoMapper::Document        
  
  # filename
  key :name, String, :required => true
  key :chapman_code, String, :required => false, :in => ChapmanCode::values+[nil]
  key :start_date, String
  key :difficulty
  key :image_file_ids, Array #, :typecast => 'ObjectId'
  many :image_files, :in => :image_file_ids
  key :template, ObjectId
#  belongs_to :template
  
  timestamps!


  def publish_to_asset_collection
    ac = AssetCollection.create(:title => self.name, :chapman_code => self.chapman_code)
    self.image_files.each do |f|
      Asset.create({
        :location => f.image_url,
        :display_width => 800,
        :height => f.height,
        :width => f.width,
        :template => Template.find(self.template),
        :asset_collection => ac
      })
    end
    ac
  end

end
