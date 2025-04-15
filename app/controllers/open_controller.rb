class OpenController < ApplicationController
  #skip_before_action :require_login

  FREEREG_RECORD_TYPE_DESCRIPTION = "baptisms, marriages and burials"
  FREECEN_RECORD_TYPE_DESCRIPTION = "census records"
  def record_type_description
    if MyopicVicar::Application.config.template_set == 'freecen'
      FREECEN_RECORD_TYPE_DESCRIPTION
    elsif MyopicVicar::Application.config.template_set == 'freereg'
      FREEREG_RECORD_TYPE_DESCRIPTION
    else
      "records"
    end
  end

  def index
    @open_counties = OpenCounty.all
    @record_types_display = record_type_description
  end

  MIN_SURNAMES_PER_PLACE = 100

  def places_for_county
    @county = params[:county]
    chapman_code = ChapmanCode.code_from_name(@county)
    @open_places = Place.chapman_code(chapman_code).not_disabled.data_present.where(:open_record_count.gt => MIN_SURNAMES_PER_PLACE).sort(:place_name => 1)
    @record_types_display = record_type_description
  end

  def surnames_for_place
    @county = params[:county]
    chapman_code = ChapmanCode.code_from_name(@county)
    place_name = params[:place]

    @place = Place.where(:place_name => place_name, :chapman_code => chapman_code).first
    @record_types_display = record_type_description
    @open_surnames = @place.open_names_per_place.where(:count.gt => MIN_SURNAMES_PER_PLACE)

  end

  def records_for_place_surname
    @county = params[:county]
    chapman_code = ChapmanCode.code_from_name(@county)
    place_name = params[:place]
    @surname = params[:surname]

    @place = Place.where(:place_name => place_name, :chapman_code => chapman_code).first
    @record_types_display = record_type_description

    @search_query = SearchQuery.new
    @search_query.last_name = @surname
    @search_query.places << @place
    @search_query.chapman_codes << chapman_code
    # open records filter goes here
    @search_query.save!  #TODO cache this!
    @open_results = @search_query.search.map{|h| SearchRecord.new(h)} unless @search_query.search
    redirect_back(fallback_location: new_search_query_path, notice: 'No records') && return if @open_results.blank?

  end

  def places_for_county_surname
  end

end
