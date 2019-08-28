class Freecen1VldFile
  include Mongoid::Document
  has_many :freecen1_vld_entries
  has_many :freecen_dwellings

  field :file_name, type: String
  field :dir_name, type: String
  field :census_type, type: String
  field :raw_year, type: String
  field :full_year, type: String
  field :piece, type: Integer
  field :series, type: String
  field :sctpar, type: String
  field :file_digest, type: String
  field :file_errors, type: Array
  class << self
    def chapman(chapman)
      where(dir_name: chapman)
    end
  end
  def chapman_code
    self.dir_name.sub(/-.*/, '')
  end
end
