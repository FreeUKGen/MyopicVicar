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
  belongs_to :freecen_dwelling
  belongs_to :freecen1_vld_entry
  has_one :search_record
  
  index(freecen_dwelling_id:1)

  # labels/values for dwelling page table body (header in freecen_dwelling)
  def self.individual_display_labels(year, chapman_code)
    if '1841' == year
      return ['Surname','Forenames','Sex','Age','Occupation','Birth County','Notes']
    elsif '1891' == year
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].member?(chapman_code)
        return ['Surname','Forenames','Relationship','Marital Status','Sex','Age','Occupation','Birth County','Birth Place','Disability','Language','Notes']
      end
      return ['Surname','Forenames','Relationship','Marital Status','Sex','Age','Occupation','Birth County','Birth Place','Disability','Notes']
    end
    #return standard fields for 1851 - 1881
    ['Surname','Forenames','Relationship','Marital Status','Sex','Age','Occupation','Birth County','Birth Place','Disability','Notes']
  end

  def individual_display_values(year, chapman_code)
    disp_age = self.age
    if self.age_unit && !self.age_unit.empty? && 'y' != self.age_unit
      disp_age = self.age + self.age_unit
    end
    disp_occupation = self.occupation
    if '1841' == year
      return [self.surname, self.forenames, self.sex, disp_age, disp_occupation, self.verbatim_birth_county, self.notes]
    elsif '1891' == year
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].member?(chapman_code)
        return [self.surname, self.forenames, self.relationship, self.marital_status, self.sex, disp_age, disp_occupation, self.verbatim_birth_county, self.verbatim_birth_place, self.disability, self.language, self.notes]
      end
      return [self.surname, self.forenames, self.relationship, self.marital_status, self.sex, disp_age, disp_occupation, self.verbatim_birth_county, self.verbatim_birth_place, self.disability, self.notes]
    end
    # standard fields for 1851 - 1881
    [self.surname, self.forenames, self.relationship, self.marital_status, self.sex, disp_age, disp_occupation, self.verbatim_birth_county, self.verbatim_birth_place, self.disability, self.notes]
  end

end
