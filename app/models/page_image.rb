class PageImage
  include Mongoid::Document
  # raw fields extrapolated from the filesystem, which has directories like
  # WIL-Urchfont-Original
  # containing files like
  # WRY-Clapham-GR-1595-1683-1-048.jpg
  # WRY-Clapham-GR-1595-1683-2-039.jpg
  field :dir_name, type: String
  field :file_name, type: String
  # values derived from the filename
  field :chapman_code, type: String
  field :place_name, type: String
  field :register_type, type: String
  field :form_number, type: Integer
  field :file_number, type: Integer
  #belongs_to :source # sources and registers may need to be created by the filesystem-to-database script if they do not exist
  #belongs_to :place # denormalization -- possibly unnecessary
  embedded_in :page
end
