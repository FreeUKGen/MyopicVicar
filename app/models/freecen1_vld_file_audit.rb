class Freecen1VldFileAudit
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'chapman_code'
  require 'freecen_constants'

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
  field :transcriber_name, type: String
  field :transcriber_email_address, type: String
  field :transcriber_userid, type: String
  field :num_entries, type: Integer, default: 0
  field :num_individuals, type: Integer, default: 0
  field :num_dwellings, type: Integer, default: 0
  field :userid, type: String
  field :action, type: String
  field :uploaded_file, type: String
  field :uploaded_file_name, type: String
  field :uploaded_file_location, type: String
  field :file_name_lower_case, type: String

  field :fc2_piece_id, type: String
  field :loaded_at, type: DateTime
  field :deleted_by, type: String

  # nb: c_at will be the date the freecen1_vld_file was deleted


  class << self
    def chapman(chapman)
      where(dir_name: chapman)
    end
  end
  # ######################################################################### instance methods

  def add_fields(vld_file, userid, loaded_date, fc2_piece_id)
    self.file_name = vld_file.file_name
    self.dir_name = vld_file.dir_name
    self.census_type = vld_file.census_type
    self.raw_year = vld_file.raw_year
    self.full_year = vld_file.full_year
    self.piece = vld_file.piece
    self.series = vld_file.series
    self.sctpar = vld_file.sctpar
    self.file_digest = vld_file.file_digest
    self.file_errors = vld_file.file_errors
    self.transcriber_name = vld_file.transcriber_name
    self.transcriber_email_address = vld_file.transcriber_email_address
    self.transcriber_userid = vld_file.transcriber_userid
    self.num_entries = vld_file.num_entries
    self.num_individuals = vld_file.num_individuals
    self.num_dwellings = vld_file.num_dwellings
    self.userid = vld_file.userid
    self.action = vld_file.action
    self.uploaded_file_name = vld_file.uploaded_file_name
    self.uploaded_file_location = vld_file.uploaded_file_location
    self.file_name_lower_case = vld_file.file_name_lower_case

    self.fc2_piece_id = fc2_piece_id
    self.loaded_at = loaded_date
    self.deleted_by = userid
  end


end
