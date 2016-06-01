class MultipleWitness
  include Mongoid::Document
  field :witness_forename, type: String
  field :witness_surname, type: String

  embedded_in :freereg1_csv_entry
  before_save :captitalize_surnames
  before_create :captitalize_surnames
  def captitalize_surnames
    self.witness_surname = self.witness_surname.upcase if self.witness_surname.present?
  end
end
