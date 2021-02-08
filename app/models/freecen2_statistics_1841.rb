class Freecen2Statistics1841
  include Mongoid::Document
  field :searches, type: Integer

  field :records, type: Hash # [chapman_code]
  field :vld_files, type: Hash
  field :csv_files, type: Hash
  field :csv_files_incorporated, type: Hash
  field :vld_entries, type: Hash
  field :csv_entries, type: Hash

  field :records_added, type: Hash
  field :vld_files_added, type: Hash
  field :csv_files_added, type: Hash
  field :csv_files_incorporated_added, type: Hash
  field :vld_entries_added, type: Hash
  field :csv_entries_added, type: Hash

  embedded_in :site_statistics_freecen
end
