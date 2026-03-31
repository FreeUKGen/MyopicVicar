# Builds a full FreeBMD entry field list with optional user corrections for contact storage / display.
class FreebmdContactFieldReport
  class << self
    def build_rows(record, corrections)
      corrections = stringify_corrections(corrections)
      rows = []
      entry_type = RecordType::display_name(record.RecordTypeID).to_s.downcase

      rows << field_row('Surname', record.Surname.to_s, corrections, 'surname')
      rows << field_row('Given Name', record.GivenName.to_s, corrections, 'given_name')
      rows << field_row('Record Type', entry_type.capitalize, corrections, nil)
      reg_date = bg_helper.format_quarter_year(record.QuarterNumber)
      rows << field_row('Registration Date', reg_date.to_s, corrections, 'registration_date')

      if entry_type == 'birth'
        cur = record.AssociateName.presence || 'No data'
        rows << field_row("Mother's Maiden Name", cur.to_s, corrections, 'mothers_maiden_name')
      end

      if entry_type == 'death'
        label = death_age_or_dob_label(record)
        cur = record.AgeAtDeath.presence || 'No data'
        rows << field_row(label, cur.to_s, corrections, 'age_or_dob')
      end

      if entry_type == 'marriage'
        cur = record.AssociateName.presence || 'No data'
        rows << field_row('Spouse Name', cur.to_s, corrections, 'spouse_name')
      end

      rows << field_row('District', record.display_district_name.to_s, corrections, 'district')
      rows << field_row('Volume', record.Volume.to_s, corrections, 'volume')

      if record.respond_to?(:register_entry_number_format) && record.register_entry_number_format
        reg_num = record.event_registration_number.presence || 'No data'
        rows << field_row('Register number', reg_num.to_s, corrections, 'register_number')
        ent_num = record.event_entry_number.presence || record.Page
        rows << field_row('Entry number', ent_num.to_s, corrections, 'entry_number')
      else
        rows << field_row('Page', record.Page.to_s, corrections, 'page')
      end

      rows
    end

    def to_plain_text(rows)
      return '' if rows.blank?

      field_lines = []
      Array(rows).each do |r|
        r = r.stringify_keys
        base = "#{r['field']}: #{r['current']}"
        if truthy?(r['corrected'])
          field_lines << "#{base}\n  → suggested correction: #{r['correction']}"
        else
          field_lines << base
        end
      end
      # Title line kept short; caller may add a banner above this block.
      header = 'Fields from the index entry (corrections shown where supplied)'
      [header, field_lines.join("\n")].join("\n\n")
    end

    private

    def bg_helper
      @bg_helper ||= Class.new { include BestGuessHelper }.new
    end

    def death_age_or_dob_label(record)
      age = record.AgeAtDeath
      if age.present? && age.to_i.to_s == age
        'Age at Death'
      else
        'Date of Birth'
      end
    end

    def field_row(label, current, corrections, correction_key)
      corr = correction_key.present? ? correction_value(corrections, correction_key) : nil
      corrected = corr.present?
      {
        'field' => label,
        'current' => current,
        'correction' => corr,
        'corrected' => corrected
      }
    end

    def correction_value(corrections, key)
      v = corrections[key.to_s]
      return nil if v.nil?

      s = v.to_s.strip
      s.presence
    end

    def stringify_corrections(c)
      return {} unless c.is_a?(Hash)

      c.stringify_keys.transform_values { |v| v.to_s }
    end

    def truthy?(v)
      v == true || v.to_s == 'true'
    end
  end
end
