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

    def update_linked_records_pob(vld_entry, birth_county, birth_place, notes)
      individual_rec = FreecenIndividual.find_by(freecen1_vld_entry_id: vld_entry.id)
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

    def valid_pob?(vld_year, verbatim_birth_county, verbatim_birth_place, birth_county, birth_place)
      result = false
      warning = ''
      result = true if birth_county == 'UNK' && birth_place == 'UNK'
      result = true if Freecen2Place.valid_chapman_code?(birth_county) && birth_place == '-'
      result = true if vld_year == '1841' && birth_county == 'OUC' && birth_place == '-'
      unless result
        alternate_pob_valid = Freecen2Place.valid_place_name?(birth_county, birth_place)
        verbatim_pob_valid = Freecen2Place.valid_place_name?(verbatim_birth_county, verbatim_birth_place)
        if alternate_pob_valid && verbatim_pob_valid || alternate_pob_valid && !verbatim_pob_valid
          result = true
        elsif !alternate_pob_valid && !verbatim_pob_valid
          result = false
          warning = 'Verbatim POB is invalid AND Alternate POB is invalid'
        elsif verbatim_pob_valid && !alternate_pob_valid
          result = false
          warning = 'Verbatim POB is valid BUT Alternate POB is invalid'
        end
      end
      [result, warning]
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

  def edits_made?(parameters)
    verbatim_changed = false
    alternative_changed = false
    notes_changed = false
    verbatim_changed = true if parameters[:verbatim_birth_county].present? && parameters[:verbatim_birth_county] != verbatim_birth_county
    verbatim_changed = true if parameters[:verbatim_birth_place].present? && parameters[:verbatim_birth_place] != verbatim_birth_place
    alternative_changed = true if parameters[:birth_county].present? && parameters[:birth_county] != birth_county
    alternative_changed = true if parameters[:birth_place].present? && parameters[:birth_place] != birth_place
    notes_changed = true if parameters[:notes].present? && parameters[:notes] != notes
    notes_changed = true if parameters[:notes].blank? && notes.present?
    [verbatim_changed, alternative_changed, notes_changed]
  end
end
