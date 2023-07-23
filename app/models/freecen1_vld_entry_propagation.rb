class Freecen1VldEntryPropagation
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :scope_year, type: String
  field :scope_county, type: String
  field :match_verbatim_birth_county, type: String
  field :match_verbatim_birth_place, type: String
  field :new_birth_county, type: String
  field :new_birth_place, type: String
  field :new_notes, type: String
  field :propagate_pob, type: Boolean
  field :propagate_notes, type: Boolean
  field :created_by, type: String


  ############################################################## class methods

  class << self

    def check_propagation_scope(prop_rec, vld_file)
      result = false
      result = true if prop_rec.scope_year == 'ALL' && prop_rec.scope_county == 'ALL'
      result = true if prop_rec.scope_year == vld_file.full_year && prop_rec.scope_county == 'ALL'
      result = true if prop_rec.scope_year == 'ALL' && prop_rec.scope_county == vld_file.dir_name
      result
    end

    def create_new_propagation(scope_year, scope_county, match_verbatim_birth_county, match_verbatim_birth_place, new_birth_county, new_birth_place, new_notes, propagate_pob, propagate_notes, userid)
      existing_prop = Freecen1VldEntryPropagation.where(scope_year: scope_year, scope_county: scope_county, match_verbatim_birth_county: match_verbatim_birth_county, match_verbatim_birth_plac: match_verbatim_birth_place).first
      if existing_prop.blank?
        new_prop = Freecen1VldEntryPropagation.new
        new_prop.scope_year = scope_year
        new_prop.scope_county = scope_county
        new_prop.match_verbatim_birth_county = match_verbatim_birth_county
        new_prop.match_verbatim_birth_place = match_verbatim_birth_place
        new_prop.new_birth_county = new_birth_county
        new_prop.new_birth_place = new_birth_place
        new_prop.new_notes = new_notes
        new_prop.propagate_pob = propagate_pob
        new_prop.propagate_notes = propagate_notes
        new_prop.created_by = userid
        new_prop.save!
        success = true
      else
        success = false
      end
      success
    end

  end

  ############################################################### instance methods

end
