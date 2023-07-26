class Freecen1VldEntry
  include Mongoid::Document
  field :age, type: String
  field :age_unit, type: String
  field :birth_county, type: String
  field :birth_place, type: String
  field :birth_place_flag, type: String
  field :civil_parish, type: String
  field :deleted_flag, type: Boolean
  field :detail_flag, type: String
  field :disability, type: String
  field :dwelling_number, type: Integer
  field :ecclesiastical_parish, type: String
  field :enumeration_district, type: String
  field :folio_number, type: String
  field :forenames, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String
  field :individual_flag, type: String
  field :language, type: String
  field :marital_status, type: String
  field :name_flag, type: String
  field :notes, type: String
  field :occupation, type: String
  field :occupation_flag, type: String
  field :page_number, type: Integer
  field :pob_valid, type: Boolean
  field :pob_warning, type: String
  field :relationship, type: String
  field :schedule_number, type: String
  field :sequence_in_household, type: Integer
  field :sex, type: String
  field :surname, type: String
  field :uninhabited_flag, type: String
  field :unoccupied_notes, type: String
  field :verbatim_birth_county, type: String
  field :verbatim_birth_place, type: String

  embeds_many :freecen1_vld_entry_edits, cascade_callbacks: true
  belongs_to :freecen1_vld_file, index: true

  ############################################################## class methods

  class << self

    def update_linked_records_pob(id, birth_county, birth_place, notes)
      individual_rec = FreecenIndividual.find_by(freecen1_vld_entry_id: id)
      return if individual_rec.blank?

      individual_rec.set(birth_county: birth_county, birth_place: birth_place, notes: notes)
      search_rec = SearchRecord.find_by(freecen_individual_id: individual_rec._id)
      return if search_rec.blank?

      search_rec.set(birth_chapman_code: birth_county, birth_place: birth_place)
    end

    def in_propagation_scope?(prop_rec, chapman_code, vld_year)
      result = false
      result = true if prop_rec.scope_year == 'ALL' && prop_rec.scope_county == 'ALL'
      result = true if prop_rec.scope_year == vld_year && prop_rec.scope_county == 'ALL'
      result = true if prop_rec.scope_year == 'ALL' && prop_rec.scope_county == chapman_code
      result
    end
  end

  ############################################################### instance methods

  def add_freecen1_vld_entry_edit(userid, reason, previous_verbatim_birth_county, previous_verbatim_birth_place, previous_birth_county, previous_birth_place, previous_notes)
    edit = Freecen1VldEntryEdit.new(editor: userid, reason: reason)
    edit[:previous_verbatim_birth_county] = previous_verbatim_birth_county
    edit[:previous_verbatim_birth_place] = previous_verbatim_birth_place
    edit[:previous_birth_county] = previous_birth_county
    edit[:previous_birth_place] = previous_birth_place
    edit[:previous_notes] = previous_notes
    freecen1_vld_entry_edits << edit
  end
end
