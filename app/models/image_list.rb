require 'chapman_code'
class ImageList 
  include MongoMapper::Document        
  
  # filename
  key :name, String, :required => true
  key :chapman_code, String, :required => false, :in => ChapmanCode::values+[nil]
  key :start_date, String, :length=>10
  key :end_date, String, :length=>10
  key :difficulty
  key :image_file_ids, Array #, :typecast => 'ObjectId'
  many :image_files, :in => :image_file_ids
  key :template, ObjectId
  key :asset_collection, ObjectId
  
#  belongs_to :template

  validates_format_of :start_date, :end_date, 
    :with => /^(\d\d\d\d(-\d\d(-\d\d)?)?)?$/, 
    :message => "Dates must be a date of the format YYYY, YYYY-MM, or YYYY-MM-DD."
  
  timestamps!


  def publish_to_asset_collection
    ac = AssetCollection.create({
      :title => self.name, 
      :chapman_code => self.chapman_code, 
      :start_date => self.start_date, 
      :end_date => self.end_date, 
      :template => self.template, 
      :difficulty => self.difficulty})
    self.image_files.each do |f|
      Asset.create({
        :location => f.image_url,
        :display_width => 1500,
        :height => f.height,
        :width => f.width,
        :template => Template.find(self.template),
        :asset_collection => ac
      })
    end
    self.asset_collection = ac.id
    self.save!
    ac
  end

end
