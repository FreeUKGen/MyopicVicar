class OpenController < ApplicationController
  skip_before_action :require_login
  skip_before_action :require_cookie_directive

  FREEREG_RECORD_TYPE_DESCRIPTION = "baptisms, marriages and burials"

  def index
    @open_counties = ChapmanCode.keys
    @record_types_display = FREEREG_RECORD_TYPE_DESCRIPTION
  end

  def places_for_county
    @county = params[:county]
    chapman_code = ChapmanCode.code_from_name(@county)
    @open_places = Place.chapman_code(chapman_code).not_disabled.data_present
    @record_types_display = FREEREG_RECORD_TYPE_DESCRIPTION
  end

  def surnames_for_place
    @county = params[:county]
    chapman_code = ChapmanCode.code_from_name(@county)
    place_name = params[:place]
    
    @place = Place.where(:place_name => place_name, :chapman_code => chapman_code).first
    @record_types_display = FREEREG_RECORD_TYPE_DESCRIPTION
    
    @open_surnames = {}
    @place.search_records.each do |search_record|
      search_record.transcript_names.each do |name|
        if name && name["last_name"]
          surname = @open_surnames[name["last_name"]] || {}
          counter = surname[search_record.record_type] || {}
          date = search_record.search_date
          earliest = counter[:earliest] || date
          latest = counter[:latest] || date
          number = counter[:number] || 0
          
          number += 1
          if earliest > date
            earliest = date
          end
          if latest < date
            latest = date
          end
          
          surname[search_record.record_type] = { :number => number, :earliest => earliest, :latest => latest }
          @open_surnames[name["last_name"]] = surname
        end
      end
    end

  end

  def records_for_place_surname
    @county = params[:county]
    chapman_code = ChapmanCode.code_from_name(@county)
    place_name = params[:place]
    @surname = params[:surname]
    
    @place = Place.where(:place_name => place_name, :chapman_code => chapman_code).first
    @record_types_display = FREEREG_RECORD_TYPE_DESCRIPTION
    
    @search_query = SearchQuery.new
    @search_query.last_name = @surname
    @search_query.places << @place
    @search_query.chapman_codes << chapman_code
    # open records filter goes here
    @search_query.save!  #TODO cache this!
    @open_results = @search_query.search.map{|h| SearchRecord.new(h)}
  end

  def places_for_county_surname
  end
end
