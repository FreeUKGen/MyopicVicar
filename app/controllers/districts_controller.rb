class DistrictsController < ApplicationController
	require 'freebmd_constants'
  skip_before_action :require_login
	def index
	  @districts = District.not_invented.all
  end

	def show
		id = params[:id]
		@district = District.where(DistrictNumber: id).first if id.present?
		@record = BestGuess.find_by(params[:entry_id])
		@search_id = params[:search_id]
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
		@record_type, @name_type, @district, @unique_names, @remainders = District.fetch_uniq_names params
		@district_number = params[:id]
		@unique_names = @unique_names.sort_by!(&:downcase)
		@unique_names.map! { |n| n.split.map!(&:capitalize).join(' ') }
		@unique_names, @remainders = @district.letterize(@unique_names)
	end

  def alphabet_selection
  	@district = District.new
    @options = FreebmdConstants::ALPHABETS[0]
    @location = 'location.href= "/districts/districts_list?params=" + this.value'
    @prompt = 'Select District Range'
  end

  def districts_list
    @character = params[:params]
    @all_districts = District.not_invented.all
    @districts = []
    @all_districts.each do |district|
      @districts << district if district.DistrictName =~ ::Regexp.new(/^[#{@character}]/)
    end
    render :index
  end
end