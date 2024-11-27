module Freecen
  class FreecenCsvPrevalidator

    def process_csv_file(csv_file, userid)

      invalid_entries = FreecenCsvEntry.where(freecen_csv_file_id: csv_file.id, record_valid: 'false', birth_place: {'$eq'=> nil}, verbatim_birth_place: {'$ne' => nil})
      updated_recs = []
      invalid_entries.each do |csv_entry|
        has_pob_warning = false
        warning_message_parts = csv_entry.warning_messages.split('<br>')
        warning_message_parts.each do |part|
          has_pob_warning = true if part.include?('Warning:') && part.include?('Verbatim Place of Birth') && part.include?('was not found so requires validation')
          break if has_pob_warning

        end
        if has_pob_warning
          was_updated = update_from_propagations(csv_entry)
          if was_updated
            updated_recs << csv_entry.record_number
          end
        end
      end
      update_csv_file(csv_file) if updated_recs.size > 0
      updated_recs
    end

    def update_from_propagations(csv_entry)
      match_found = false
      propagation_match = Freecen1VldEntryPropagation.where(match_verbatim_birth_county: csv_entry.verbatim_birth_county, match_verbatim_birth_place: csv_entry.verbatim_birth_place, scope_year: 'ALL', scope_county: 'ALL').first
      if propagation_match.present?
        if propagation_match.propagate_pob
          warning_message = csv_entry.warning_messages + "Warning: Alternate fields have been adjusted and need review.<br>"
          csv_entry.update_attributes(birth_county: propagation_match.new_birth_county, birth_place: propagation_match.new_birth_place, warning_messages: warning_message)
        end
        if propagation_match.propagate_notes
          the_notes = csv_entry.notes.blank? ? propagation_match.new_notes : "#{csv_entry.notes} #{propagation_match.new_notes}"
          warning_message = csv_entry.warning_messages + "Warning: Notes field has been adjusted and needs review.<br>"
          csv_entry.update_attributes(notes: the_notes, warning_messages: warning_message)
        end
        match_found = true
      end
      match_found
    end

    def update_csv_file(file)
      file.update_attribute(:locked_by_transcriber,true) # lock so that it ca'nt be replaced without being downloaded first.
    end

  end
end
