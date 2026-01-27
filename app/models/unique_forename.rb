class UniqueForename
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :Name, type: String
  field :count, type: Integer
  index( {Name: 1}, {background: true})

  def self.export_to_csv_file(file_path = nil)
    file_path ||= Rails.root.join('tmp', "unique_forenames_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv")

    CSV.open(file_path, 'wb') do |csv|
      csv << ['name', 'count']
      UniqueForename.where(count: {"$ne" => 0}).all.each do |record|
        csv << [record.Name, record.count]
      end
    end

    file_path
  end
end