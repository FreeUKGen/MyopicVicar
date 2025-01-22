class DistrictsController < ApplicationController
  require 'freebmd_constants'
  skip_before_action :require_login
	def index
	  @districts = District.not_invented.all
  end

	def show
		id = params[:id]
		@district = District.where(DistrictNumber: id).first if id.present?
		@search_query = SearchQuery.find(params[:search_id]) if params[:search_id].present?
		@search_record = BestGuess.find(params[:entry_id]) if params[:entry_id].present?
		birth_uniq_name = DistrictUniqueName.where(district_number: @district.DistrictNumber, record_type: 1).first
		marriage_uniq_name =  DistrictUniqueName.where(district_number: @district.DistrictNumber, record_type: 3).first
		death_uniq_name =  DistrictUniqueName.where(district_number: @district.DistrictNumber, record_type: 2).first
		@birth_uniq_surname_count = birth_uniq_name.present? ? birth_uniq_name.unique_surnames.count : "none"
		@birth_uniq_forename_count = birth_uniq_name.present? ? birth_uniq_name.unique_forenames.count : "none"
		@marriage_uniq_surname_count = marriage_uniq_name.present? ? marriage_uniq_name.unique_surnames.count : "none"
		@marriage_uniq_forename_count = marriage_uniq_name.present? ? marriage_uniq_name.unique_forenames.count : "none"
		@death_uniq_surname_count = death_uniq_name.present? ? death_uniq_name.unique_surnames.count : "none"
		@death_uniq_forename_count = death_uniq_name.present? ? death_uniq_name.unique_forenames.count : "none"
	end

	def unique_district_names
		@record_type = "birth"
		@record_type = params[:record_type] if params[:record_type].present?
		record_type_id = RecordType::FREEBMD_OPTIONS[@record_type.upcase]
		@name_type = "1"
		@name_type = params[:name_type] if params[:name_type].present?
		@district_number = params[:id]
		@district = District.where(DistrictNumber: @district_number).first
		if @name_type == "0"
			@unique_names_0 = DistrictUniqueName.where(district_number: @district_number, record_type: record_type_id).first.unique_surnames
		else
			@unique_names_0 = DistrictUniqueName.where(district_number: @district_number, record_type: record_type_id).first.unique_forenames
		end
		@unique_names = @unique_names_0.sort_by!(&:downcase)
		@unique_names.map!(&:titleize)
		@unique_names, @remainders = @district.letterize(@unique_names)
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
    @character = params[:params]
    @all_districts = District.not_invented.all
    @districts = []
    @all_districts.each do |district|
      @districts << district if district.DistrictName =~ ::Regexp.new(/#{@character}/)
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
end