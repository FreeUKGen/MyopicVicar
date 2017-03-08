class RefreshUcfList
  attr_accessor :model_name

  def initialize model_name
    @model_name = model_name
  end

  SPECIAL_CHARACTER_LISTS = /[?{}\[\]]/

  def filter_id
    retrieve_name_columns.each do |name|
      $stdout.reopen(new_file(name), "w")
      puts "#{name}"
      @model_name.where(name.to_sym => SPECIAL_CHARACTER_LISTS).each do |record| 
        puts "#{record.id}\n"
      end
    end
  end

  private

  # Fetch all the column attribute names from the table
  def fetch_columns
    @model_name.attribute_names
  end

  # Retrieve the column attribute where like 'name'
  def retrieve_name_columns
    fetch_columns.grep /name/
  end

  # Create a new file named as current date and time
  def new_file name
    file_name = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{name}.txt"
    Rails.root.to_s + "/script/refresh_ucf/#{file_name}"
  end
end