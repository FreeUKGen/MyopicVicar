class FreecenIndividual
  include Mongoid::Document
  field :sequence_in_household, type: Integer
  field :individual_flag, type: String
  field :surname, type: String
  field :forenames, type: String
  field :name_flag, type: String
  field :relationship, type: String
  field :marital_status, type: String
  field :sex, type: String
  field :age, type: String
  field :age_unit, type: String
  field :detail_flag, type: String
  field :occupation, type: String
  field :occupation_flag, type: String
  field :birth_county, type: String
  field :birth_place, type: String
  field :verbatim_birth_county, type: String
  field :verbatim_birth_place, type: String
  field :birth_place_flag, type: String
  field :disability, type: String
  field :language, type: String
  field :notes, type: String

  belongs_to :freecen1_vld_file, index: true
  belongs_to :freecen_dwelling, index: true
  belongs_to :freecen1_vld_entry, index: true
  belongs_to :freecen2_place, optional: true, index: true
  belongs_to :freecen2_piece, optional: true, index: true
  belongs_to :freecen_piece, optional: true, index: true

  has_one :search_record, dependent: :restrict_with_error, autosave: true

  before_destroy :destroy_search_record

  index(freecen_dwelling_id: 1)
  index({ birth_county: 1, birth_place: 1 }, name: 'birth_county_birth_place')
  index({ birth_county: 1, verbatim_birth_place: 1 }, name: 'birth_county_verbatim_birth_place')
  index({ verbatim_birth_county: 1, birth_place: 1 }, name: 'verbatim_birth_county_birth_place')
  index({ verbatim_birth_county: 1, verbatim_birth_place: 1 }, name: 'verbatim_birth_county_verbatim_birth_place')

  # labels/values for dwelling page table body (header in freecen_dwelling)
  def self.individual_display_labels(year, chapman_code)
    if year == '1841'
      return ['Surname', 'Forenames', 'Sex', 'Age', 'Occupation', 'Birth County', 'Notes']
    elsif year == '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return ['Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Birth County', 'Birth Place', 'Disability', 'Language', 'Notes']
      end
      return ['Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Birth County', 'Birth Place', 'Disability', 'Notes']
    end
    #return standard fields for 1851 - 1881
    ['Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Birth County', 'Birth Place', 'Disability', 'Notes']
  end

  def individual_display_values(year, chapman_code)
    birth = birth_place
    birth = birth + ' (or ' + verbatim_birth_place + ')' if birth_place.present? && verbatim_birth_place.present? && birth_place != verbatim_birth_place
    birth = verbatim_birth_place if birth_place.blank?
    birth_county_name = ChapmanCode.name_from_code(birth_county)
    verbatim_birth_county_name = ChapmanCode.name_from_code(verbatim_birth_county)
    birth_county_name = birth_county_name + ' (or ' + verbatim_birth_county_name + ')' if birth_county_name.present? &&
      verbatim_birth_county_name.present? && birth_county_name != verbatim_birth_county_name
    birth_county_name = verbatim_birth_county_name if birth_county_name.blank?

    if age == '999'
      disp_age = 'unk'
    else
      disp_age = age
      if age_unit.present? && 'y' != age_unit
        disp_age = age + age_unit
      end
    end
    disp_occupation = occupation
    if year == '1841'
      return [surname, forenames, sex, disp_age, disp_occupation, birth_county_name, notes]
    elsif year == '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return [surname, forenames, relationship, marital_status, sex, disp_age, disp_occupation, birth_county_name, birth, disability, language, notes]
      end
      return [surname, forenames, relationship, marital_status, sex, disp_age, disp_occupation, birth_county_name, birth, disability, notes]
    end
    # standard fields for 1851 - 1881
    [surname, forenames, relationship, marital_status, sex, disp_age, disp_occupation, birth_county_name, birth, disability, notes]
  end

  def destroy_search_record
    self.search_record.destroy if self.search_record.present?
  end
end
