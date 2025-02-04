module DownloadAsCsv
  extend ActiveSupport::Concern
  SEARCH_RESULTS_ATTRIBUTES = %w[GivenName Surname RecordType Quarter District Volume Page AssociateName AgeAtDeath].freeze
  FIELDS = ["First Name", "Surname", "Record Type", "Registration Date", "Registration District", "Volume", "Page", "Mother's Maiden Name", "Spouse's Surname", "Age at Death/Date of Birth" ].freeze
  DOB_START_QUARTER = 530
  SPOUSE_SURNAME_START_QUARTER = 301
  EVENT_YEAR_ONLY = 589


  def search_results_csv(array)
    CSV.generate(headers: true) do |csv|
      csv << ['You can only download 50 results.']
      csv << FIELDS
      array.each do |record|
        format_csv_data(record)
        record = record.except!('AssociateName')
        csv << SEARCH_RESULTS_ATTRIBUTES.map{ |attr| record[attr] }
      end
    end
  end

  def gedcom_header
    today = Date.today
    now = Time.now.strftime('%T')
    arr = ['0 HEAD', '1 SOUR freebmd.org.uk',
           '2 NAME Free UK Genealogy FreeBMD project',
           '1 DATE '+today.to_s,
           '2 TIME '+now+' UTC',
           '1 CHAR UTF-8',
           '1 FILE '+today.to_s+'.ged',
           '1 GEDC',
           '2 VERS 5.5.1',
           '2 FORM LINEAGE-LINKED',
           '1 NOTE This file contains private information and may not be redistributed, published, or made public.']
    arr
  end
  def search_results_gedcom(array)
    gedcom = []
    gedcom << gedcom_header
    i = 0
    f = 0
    array.each do |record|
      unless record.nil?
      qn = record[:QuarterNumber]
      quarter = qn >= EVENT_YEAR_ONLY ? QuarterDetails.quarter_year(qn) : QuarterDetails.quarter_human(qn)
      surname = record[:Surname]
      given_names = record[:GivenName].split(' ')
      given_name = given_names[0]
      given_names.shift()
      other_given_names = given_names.join(' ') if given_names.present?
      entry = BestGuess.where(RecordNumber: record[:RecordNumber]).first
      i = i+1
      f = f+1 if record[:RecordTypeID] == 3
      gedcom << ''
      gedcom << '0 @'+i.to_s+'@ INDI'
      gedcom << '1 NAME '+given_name+' /'+surname+'/'
      gedcom << '2 SURN '+surname
      gedcom << '2 GIVN '+given_name
      gedcom << '2 _MIDN '+other_given_names if other_given_names.present?
      gedcom << '1 BIRT' if record[:RecordTypeID] == 1
      gedcom << '1 DEAT' if record[:RecordTypeID] == 2
      gedcom << '1 MARR' if record[:RecordTypeID] == 3
      gedcom << '2 DATE '+quarter
      gedcom << '2 PLAC '+record[:District]
      gedcom << '1 WWW '+'https://www.freebmd.org.uk/search_records/'+entry.record_hash+'/'+entry.friendly_url
      end
    end
    gedcom
  end

  private

  def format_csv_data(record)
    qn = record['QuarterNumber']
    record['Quarter'] = format_quarter(qn)
    record['RecordType'] = format_record_type(record[:RecordTypeID])

    case record['RecordType']
    when 'BIRTHS'
      record['MotherMaidenName'] = record['AssociateName'].presence || 'No data'
      record['SpouseSurname'] = ''
      record['AgeAtDeathOrDateOfBirth'] = ''
    when 'DEATHS'
      record['MotherMaidenName'] = ''
      record['SpouseSurname'] = ''
      record['AgeAtDeathOrDateOfBirth'] = record['AgeAtDeath'].presence || 'No data'
    when 'MARRIAGES'
      record['MotherMaidenName'] = ''
      record['SpouseSurname'] = record['AssociateName'].presence || 'No data'
      record['AgeAtDeathOrDateOfBirth'] = ''
    end
  end

  def format_quarter(quarter_number)
    if quarter_number >= SearchQuery::EVENT_YEAR_ONLY
      QuarterDetails.quarter_year(quarter_number)
    else
      QuarterDetails.quarter_human(quarter_number)
    end
  end

  def format_record_type(record_type_id)
    RecordType.display_name([record_type_id.to_s])
  end

end