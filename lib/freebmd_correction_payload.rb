# Builds JSON payload for FreeBMD1 create-correction API from a Contact (Data Problem report).
class FreebmdCorrectionPayload
  # Labels aligned with FreeBMD1 corrections.pl field titles.
  CORRECTION_FIELD_LABELS = {
    'surname' => 'Surname:        ',
    'given_name' => 'Given names:    ',
    'registration_date' => 'Registration:   ',
    'mothers_maiden_name' => "Mother's name:  ",
    'age_or_dob' => 'Age at Death:   ',
    'spouse_name' => 'Spouse name:    ',
    'district' => 'District:       ',
    'volume' => 'Volume:         ',
    'register_number' => 'Register:       ',
    'entry_number' => 'Entry:          ',
    'page' => 'Page:           ',
    'registered' => 'Registered:     ',
    'marriage_submission_entry_number' => 'Entry number:   ',
    'marriage_submission_source_code' => 'SourceCode:     ',
    'marriage_submission_registered' => 'Registered:     '
  }.freeze

  SECTION3_FIELD_LABELS = {
    'event' => 'Event:          ',
    'year' => 'Year:           ',
    'quarter' => 'Quarter:        ',
    'surname' => 'Surname:        ',
    'forename' => 'Given names:    ',
    'mothers_maiden_name' => "Mother's name:  ",
    'age_or_dob' => 'Age at Death:   ',
    'spouse_name' => 'Spouse name:    ',
    'district' => 'District:       ',
    'volume' => 'Volume:         ',
    'register_number' => 'Register number:',
    'entry_number' => 'Entry number:   ',
    'page_number' => 'Page:           ',
    'registered' => 'Registered:     ',
    'marriage_submission_entry_number' => 'Entry number:   ',
    'marriage_submission_source_code' => 'SourceCode:     ',
    'marriage_submission_registered' => 'Registered:     '
  }.freeze

  MISSING_ENTRY_SUBSECTION_IDS = %w[2].freeze

  class << self
    def build(contact)
      sd = stringify_hash(contact.session_data)
      corrections_hash = sd['corrections'].is_a?(Hash) ? sd['corrections'].stringify_keys : {}
      section3 = sd['section3'].is_a?(Hash) ? sd['section3'].stringify_keys : {}

      missing = missing_entry_report?(contact, section3)
      multiple = multiple_entries?(corrections_hash, section3)

      correction_pairs = build_correction_pairs(corrections_hash, section3, missing)
      corrections_text = describe_issue_text(contact, correction_pairs, missing)

      source = sd['source'].to_s.strip
      source = default_source if source.blank?
      extra = sd['reporter_comments'].to_s.strip
      source = "#{source}\n\nAdditional comments:\n#{extra}" if extra.present?

      payload = {
        database: database_name,
        record_number: contact.record_id.to_i,
        email: contact.email_address.to_s.strip,
        source: source,
        missing: missing,
        multiple: multiple,
        freebmd2_contact_id: contact.id.to_s,
        dry_run: false
      }
      payload[:corrections] = correction_pairs if correction_pairs.any?
      payload[:corrections_text] = corrections_text if corrections_text.present?
      payload
    end

    private

    def stringify_hash(value)
      return {} if value.blank?

      h = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
      h = h.to_hash if h.respond_to?(:to_hash) && !h.is_a?(Hash)
      h.stringify_keys
    rescue StandardError
      {}
    end

    def database_name
      if defined?(FREEBMD_DB) && FREEBMD_DB.is_a?(Hash)
        name = FREEBMD_DB['database'] || FREEBMD_DB[:database]
        return name.to_s if name.present?
      end

      Postem.connection.current_database.to_s
    end

    def default_source
      'FreeBMD2 error report — information from GRO index scan on site'
    end

    def missing_entry_report?(contact, section3)
      return true if MISSING_ENTRY_SUBSECTION_IDS.include?(contact.query.to_s)

      section3.except('multiple_entries').values.any?(&:present?)
    end

    def multiple_entries?(corrections_hash, section3)
      corrections_hash['multiple_entries'].to_s == '1' ||
        section3['multiple_entries'].to_s == '1'
    end

    def build_correction_pairs(corrections_hash, section3, missing)
      pairs = []

      unless missing
        corrections_hash.each do |key, val|
          next if val.blank?
          next if key == 'multiple_entries'

          label = CORRECTION_FIELD_LABELS[key] || "#{humanize_key(key)}: "
          pairs << [label, val.to_s.strip]
        end
        return pairs
      end

      ContactsHelper::FREEBMD_SECTION3_DISPLAY_ORDER.each do |key|
        val = section3[key]
        next if val.blank?
        next if key == 'multiple_entries'

        label = SECTION3_FIELD_LABELS[key] || "#{ContactsHelper::FREEBMD_SECTION3_LABELS[key] || humanize_key(key)}: "
        pairs << [label, val.to_s.strip]
      end
      pairs
    end

    def describe_issue_text(contact, correction_pairs, missing)
      return nil if missing
      return nil if correction_pairs.any?

      body = contact.body.to_s.strip
      return body if body.present?

      subsection = FreebmdDataProblem.subsection_by_id(contact.query)
      return nil unless subsection

      "FreeBMD2 report (#{subsection[:label]})."
    end

    def humanize_key(key)
      key.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
    end
  end
end
