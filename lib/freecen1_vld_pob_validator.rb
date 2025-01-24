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
      verbatim_reason = ''
      should_be_hyphen = ['(-)', "'-'", "'-", "-'"]

      if vld_entry.birth_place.blank?
        reason = 'Automatic update of birth place missing to hyphen'
        new_birth_place = '-'
      elsif vld_entry.birth_place.upcase == 'UNK'
        reason = 'Automatic update of birth place UNK to hyphen'
        new_birth_place = '-'
      elsif vld_entry.birth_place.in?(should_be_hyphen)
        reason = "Automatic update of birth place #{vld_entry.birth_place} to hyphen"
        new_birth_place = '-'
      else
        new_birth_place, reason = replace_chars_with_space(vld_entry.birth_place)
        new_verbatim_birth_place, verbatim_reason = replace_chars_with_space(vld_entry.verbatim_birth_place)
      end

      if vld_entry.verbatim_birth_place.in?(should_be_hyphen)
        verbatim_reason = "Automatic update of verbatim birth place #{vld_entry.verbatim_birth_place} to hyphen"
        new_verbatim_birth_place = '-'
      end

      if reason.present? || verbatim_reason.present?
        if reason.present?
          vld_entry.add_freecen1_vld_entry_edit(userid, reason, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place, vld_entry.notes)
          vld_entry.set(birth_place: new_birth_place)
          Freecen1VldEntry.update_linked_records_pob(vld_entry, vld_entry.birth_county, new_birth_place, vld_entry.notes)
        end
        if verbatim_reason.present?
          vld_entry.add_freecen1_vld_entry_edit(userid, verbatim_reason, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place, vld_entry.notes)
          vld_entry.set(verbatim_birth_place: new_verbatim_birth_place)
          Freecen1VldEntry.update_linked_individual_rec_verbatim_pob(vld_entry, new_verbatim_birth_place)
        end
      end

      pob_valid, pob_warning = valid_pob?(vld_entry, vld_year)

      if pob_valid
        individual_rec = FreecenIndividual.find_by(freecen1_vld_entry_id: vld_entry.id)
        if individual_rec.present?
          search_rec = SearchRecord.find_by(freecen_individual_id: individual_rec._id)
          if search_rec.present?
            place = vld_entry.birth_place.presence || vld_entry.verbatim_birth_place
            valid_pob, place_id = Freecen2Place.valid_place(vld_entry.birth_county, place)
            valid_pob ? search_rec.set(freecen2_place_of_birth: place_id) : search_rec.set(freecen2_place_of_birth: nil)
          end
        end
      else
        propagation_matches = FreecenPobPropagation.where(match_verbatim_birth_county: vld_entry.verbatim_birth_county, match_verbatim_birth_place: vld_entry.verbatim_birth_place)
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
            pob_valid = true
            pob_warning = ''
          end
        end
      end

      vld_entry.set(pob_valid: pob_valid, pob_warning: pob_warning)
      pob_valid
    end

    def replace_chars_with_space(place_of_birth)
      updated_place_of_birth = place_of_birth
      update_reason = ''
      has_char = false
      chars = ',.'
      chars.each_char do |char|
        has_char = true if place_of_birth.include?(char)
        break if has_char
      end
      if has_char
        updated_place_of_birth = place_of_birth.tr(',.', ' ').squeeze(' ')
        update_reason = "Automatic update of birth place replacing #{chars} with space/UNK"
        updated_place_of_birth = '-' if (updated_place_of_birth == ' ' || updated_place_of_birth.blank?)
      end
      [updated_place_of_birth, update_reason]
    end

    def valid_pob?(vld_entry, vld_year)
      result = false
      warning = ''
      result, warning = Freecen1VldEntry.valid_pob?(vld_year, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place)
      [result, warning]
    end
  end
end
