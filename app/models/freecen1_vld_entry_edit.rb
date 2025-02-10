class Freecen1VldEntryEdit
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :editor, type: String
  field :reason, type: String
  field :created, type: DateTime
  field :previous_verbatim_birth_county, type: String
  field :previous_verbatim_birth_place, type: String
  field :previous_birth_county, type: String
  field :previous_birth_place, type: String
  field :previous_notes, type: String
  embedded_in :freecen1_vld_entry
end
