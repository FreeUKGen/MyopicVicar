class RefreshUcfList
  attr_accessor :model_name

  def initialize model_name
    @model_name = model_name
  end

  SPECIAL_CHARACTER_LISTS = /[?{}\[\]]/

  def filter_id
    retrieve_name_columns.each do |name|
      original_stdout = STDOUT.clone
      STDOUT.reopen(new_file(name), "w")
      special_character_records(name).each do |record| 
        puts "#{record.id}\n"
      end
      STDOUT.reopen(original_stdout)
      puts "Total number of ids for #{name}: #{special_character_records(name).count}"
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

  # Retrieve the special character records from the model
  def special_character_records column_name
    @model_name.where(column_name.to_sym => SPECIAL_CHARACTER_LISTS)
  end

  # Create a new file named as current date and time
  def new_file name
    file_name = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{name}.txt"
    Rails.root.to_s + "/script/refresh_ucf/#{file_name}"
  end
end