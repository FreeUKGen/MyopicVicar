
task :check_freecen_pob_propagations,[:option] => :environment do

  added_recs = 0
  old_recs = Freecen1VldEntryPropagation.count
  new_recs = FreecenPobPropagation.count

  p "Freecen1VldEntryPropagation record count = #{old_recs}"
  p "FreecenPobPropagation record count = #{new_recs}"

  if old_recs == new_recs
    p "Record counts match - no action required"
  else
    Freecen1VldEntryPropagation.each  do |old|
      new = FreecenPobPropagation.where(id: old.id)
      next if new.present?

      add_prop = FreecenPobPropagation.new
      add_prop._id = old._id
      add_prop.scope_year = old.scope_year
      add_prop.scope_county = old.scope_county
      add_prop.match_verbatim_birth_county = old.match_verbatim_birth_county
      add_prop.match_verbatim_birth_place = old.match_verbatim_birth_place
      add_prop.new_birth_county = old.new_birth_county
      add_prop.new_birth_place = old.new_birth_place
      add_prop.new_notes = old.new_notes
      add_prop.propagate_pob = old.propagate_pob
      add_prop.propagate_notes = old.propagate_notes
      add_prop.created_by = old.created_by
      add_prop.save!
      success = true
      added_recs += 1

    end
    p "Added #{added_recs} FreecenPobPropagation records"
  end
end
