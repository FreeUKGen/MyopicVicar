module Freecen
  class Freecen1VldPobValidator

    def process_vld_file(chapman_code, vld_file, userid)

      vld_year = vld_file.full_year

      invalid_pob_entries = Freecen1VldEntry.where(freecen1_vld_file_id: vld_file.id, pob_valid: false).or(Freecen1VldEntry.where(freecen1_vld_file_id: vld_file.id, pob_valid: nil))
      num_pob_valid = Freecen1VldEntry.where(freecen1_vld_file_id: vld_file.id, pob_valid: true).count

      invalid_pob_entries.each do |vld_entry|
        is_individual = FreecenIndividual.where(freecen1_vld_entry_id: vld_entry.id)
        next if is_individual.blank? # IE not an individual

        num_pob_valid += 1 if individual_pob_valid?(vld_entry, chapman_code, vld_year, userid)

      end
      num_pob_valid
    end

    def individual_pob_valid?(vld_entry, chapman_code, vld_year, userid)
      pob_valid = false
      pob_warning = ''
      reason = ''
      @linked_records_updated = false

      if vld_entry.birth_place.blank?
        reason = 'Automatic update of birth place missing to hyphen'
      elsif vld_entry.birth_place.upcase == 'UNK'
        reason = 'Automatic update of birth place UNK to hyphen'
      end

      if reason.present?
        vld_entry.add_freecen1_vld_entry_edit(userid, reason, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place, vld_entry.notes)
        vld_entry.set(birth_place: '-')
        Freecen1VldEntry.update_linked_records_pob(vld_entry, vld_entry.birth_county, '-', vld_entry.notes)
        @linked_records_updated = true
        vld_entry.reload
      end

      pob_valid, pob_warning = valid_pob?(vld_entry, vld_year)

      unless pob_valid
        propagation_matches = Freecen1VldEntryPropagation.where(match_verbatim_birth_county: vld_entry.verbatim_birth_county, match_verbatim_birth_place: vld_entry.verbatim_birth_place)
        if propagation_matches.present?

          propagation_matches.each do |prop_rec|
            in_scope = Freecen1VldEntry.in_propagation_scope?(prop_rec, chapman_code, vld_year)
            next unless in_scope

            reason = "Propagation (id = #{prop_rec._id})"
            vld_entry.add_freecen1_vld_entry_edit(userid, reason, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place, vld_entry.notes)
            vld_entry.set(birth_county: prop_rec.new_birth_county, birth_place: prop_rec.new_birth_place) if prop_rec.propagate_pob
            if prop_rec.propagate_notes
              the_notes = vld_entry.notes.blank? ? prop_rec.new_notes : "#{vld_entry.notes} #{prop_rec.new_notes}"
              vld_entry.set(notes: the_notes)
            end
            Freecen1VldEntry.update_linked_records_pob(vld_entry, vld_entry.birth_county, vld_entry.birth_place, vld_entry.notes)
            @linked_records_updated = true
            pob_valid = true
            pob_warning = ''
          end
        end
      end

      vld_entry.set(pob_valid: pob_valid, pob_warning: pob_warning)
      # VLD files processed by the monthly upload do not set the birth_place on the search record (manually uploaded VLD files do)
      # only do if update_linked_records_pob has not been called  as that method will do it
      Freecen1VldEntry.set_search_record_pob_place(vld_entry, vld_entry.birth_place) unless @linked_records_updated == true
      pob_valid
    end

    def valid_pob?(vld_entry, vld_year)
      result = false
      warning = ''
      result, warning = Freecen1VldEntry.valid_pob?(vld_year, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place)
      [result, warning]
    end
  end
end
