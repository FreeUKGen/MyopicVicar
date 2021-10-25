class DistrictsController < ApplicationController
	skip_before_action :require_login
	def index
		@districts = District.not_invented.all
	end

	def show
		@district = District.where(DistrictNumber: params[:id]).first
	end

	def unique_district_names
		@record_type = params[:record_type] || "birth"
		record_type_id = RecordType::FREEBMD_OPTIONS[@record_type.upcase]
		@name_type = params[:name_type] || 1
		@district_number = params[:id]
		@district = District.where(DistrictNumber: @district_number).first
		if @name_type == 0
			@unique_names = DistrictUniqueName.where(district_number: @district_number, record_type: record_type_id).first.unique_surnames
		else
			@unique_names = DistrictUniqueName.where(district_number: @district_number, record_type: record_type_id).first.unique_forenames
		end
		@unique_names, @remainders = @district.letterize(@unique_names)
	end

end