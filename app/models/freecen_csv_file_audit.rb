class FreecenCsvFileAudit
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'chapman_code'
  require 'freecen_constants'


  field :chapman_code, type: String
  field :file_name, type: String
  field :total_records, type: Integer
  field :transcriber_name, type: String
  field :userid, type: String
  field :year, type: String
  field :total_dwellings, type: Integer
  field :total_individuals, type: Integer
  field :completes_piece, type: Boolean, default: false


  field :fc2_piece_id, type: String
  field :loaded_at, type: DateTime
  field :action_by, type: String
  field :action_type, type: String

  # nb: c_at will be the date the freecen_csv_file was unincorporated/deleted

  class << self
    def chapman_code(chapman_code)
      where(chapman_code: chapman_code)
    end
  end

  # ######################################################################### instance methods

  def add_fields(action_type, csv_file, userid, fc2_piece_id)
    self.chapman_code = csv_file.chapman_code
    self.file_name = csv_file.file_name
    self.year = csv_file.year
    self.transcriber_name = csv_file.transcriber_name
    self.total_records = csv_file.total_records
    self.total_individuals = csv_file.total_individuals
    self.total_dwellings = csv_file.total_dwellings
    self.userid = csv_file.userid
    self.completes_piece = csv_file.completes_piece

    self.fc2_piece_id = fc2_piece_id
    self.loaded_at = csv_file.uploaded_date
    self.action_by = userid
    self.action_type = action_type
  end

end
