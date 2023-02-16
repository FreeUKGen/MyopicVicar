module DownloadAsCsv
  extend ActiveSupport::Concern
  SEARCH_RESULTS_ATTRIBUTES = %w{ GivenName Surname RecordType Quarter District Volume Page }
  FIELDS = ["Given Name", "Surname", "Record Type", "Quarter", "District", "Volume", "Page" ]

  def search_results_csv(array)
    CSV.generate(headers: true) do |csv|
      csv << FIELDS
      array.each do |record|
        qn = record[:QuarterNumber]
        quarter = qn >= SearchQuery::EVENT_YEAR_ONLY ? QuarterDetails.quarter_year(qn) : QuarterDetails.quarter_human(qn)
        record_type = RecordType::display_name(["#{record[:RecordTypeID]}"])
        record["RecordType"] = record_type
        record["Quarter"] = quarter
        csv << SEARCH_RESULTS_ATTRIBUTES.map{ |attr| record[attr] }
      end
    end
  end
end