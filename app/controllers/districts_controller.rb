class DistrictsController < ApplicationController
  require 'freebmd_constants'
  skip_before_action :require_login
	def index
	  @districts = District.not_invented.all
  end

	def show
		@district = get_district(params[:id])
    @search_query = get_search_query(params[:search_id])
    @search_record = get_entry(params[:entry_id])
    if @district
      @birth_count, @birth_uniq_surname_count, @birth_uniq_forename_count = fetch_unique_name_counts(@district.DistrictNumber, 1)
      @marriage_count, @marriage_uniq_surname_count, @marriage_uniq_forename_count = fetch_unique_name_counts(@district.DistrictNumber, 3)
      @death_count, @death_uniq_surname_count, @death_uniq_forename_count = fetch_unique_name_counts(@district.DistrictNumber, 2)
    end
	end

	def unique_district_names
		@record_type = params[:record_type].presence || 'birth'
		record_type_id = district_unique_names_record_type_id(@record_type)
		@name_type = params[:name_type].presence || '1'
		@district_number = params[:id]
		@district = District.where(DistrictNumber: @district_number).first
		district_no = @district_number.to_i
		unique_row = DistrictUniqueName.find_by(district_number: district_no, record_type: record_type_id)
		@unique_names_0 =
			if @name_type == '0'
				Array(unique_row&.unique_surnames).compact
			else
				Array(unique_row&.unique_forenames).compact
			end
		if params[:filter].present?
			@filter = params[:filter].downcase
			pattern = ::Regexp.new(/#{@filter}/)
			@unique_names_filtered = []
			@unique_names_0.each do |name|
				@unique_names_filtered << name if pattern.match(name.downcase)
			end
			@unique_names = @unique_names_filtered.sort_by!(&:downcase)
		else
				@unique_names = @unique_names_0.sort_by!(&:downcase)
		end
		@unique_names.map!(&:titleize)
		letterize_subject = @district || District.new
		@unique_names, @remainders = letterize_subject.letterize(@unique_names)
	end

  def alphabet_selection
  	@district = District.new
    @options = FreebmdConstants::ALPHABETS[0]
    @location = 'location.href= "/districts/districts_list?params=" + this.value'
    @prompt = 'Select District Range'
	end

  def county_selection
		@county = County.new
		@options = ['Aberdeenshire', 'Cheshire']
		@location = 'location.href= "/counties/show?params=" + this.value'
		@prompt = 'Select County'
	end

	def district_selection
		@districts = District.new
		@options = districts_as_array
		@location = 'location.href= "/districts/districts_list?params=" + this.value'
		@prompt = 'Select District'
	end

	def districts_list
    @character = params[:params].downcase
    @all_districts = District.not_invented.all
    @districts = []
    @all_districts.each do |district|
      @districts << district if district.DistrictName.downcase =~ ::Regexp.new(/#{@character}/)
		end
		@districts = @districts.sort_by { |district| [district.DistrictName]}
    render :index
	end

  def districts_hash
		@all_districts = District.not_invented.all
		hash = Hash.new
		@all_districts.each do |district|
			hash[district.DistrictName] = district.DistrictNumber
		end
		hash
	end

	def district_page_map
		id = params[:id]
		@district = District.where(DistrictNumber: id).first if id.present?
	end

	def year_page_map
		@year = params[:year]
		@quarter = params[:quarter]
		@event_type = params[:event_type]
	end

	private

	def get_district(id=nil)
		District.find_by(DistrictNumber: id) if id.present?
	end

	def get_search_query(search_id=nil)
    SearchQuery.find(search_id) if search_id.present?
  end

  def get_entry(entry_id=nil)
    BestGuess.find(entry_id) if entry_id.present?
  end

  def fetch_unique_name_counts(district_number, record_type)
    unique_name = DistrictUniqueName.find_by(district_number: district_number, record_type: record_type)
    count = unique_name.present? ? unique_name.total_records : 0
    uniq_surname_count = unique_name.present? ? Array(unique_name.unique_surnames).compact.count : 'none'
    uniq_forename_count = unique_name.present? ? Array(unique_name.unique_forenames).compact.count : 'none'
    [count, uniq_surname_count, uniq_forename_count]
  end

  # DistrictUniqueName.record_type is 1 / 2 / 3. Params may be malformed (e.g. trailing punctuation in URLs).
  def district_unique_names_record_type_id(record_type_param)
    raw = record_type_param.to_s.strip
    # Mangled query strings, e.g. record_type=birthpe=birth — prefer last segment after '='.
    raw = raw.split('=').last.strip if raw.include?('=')

    letters_only = raw.upcase.gsub(/[^A-Z]/, '')
    return RecordType::BIRTHS if letters_only.blank?

    return RecordType::MARRIAGES if letters_only.start_with?('MARRIAGE')
    return RecordType::DEATHS if letters_only.start_with?('DEATH')
    return RecordType::BIRTHS if letters_only.start_with?('BIRTH')

    mapped = RecordType::FREEBMD_OPTIONS[letters_only]
    case mapped
    when Integer then mapped
    when Array then mapped.first.to_i
    else RecordType::BIRTHS
    end
  end
end