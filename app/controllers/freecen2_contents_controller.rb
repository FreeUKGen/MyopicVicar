# Manages the collection of FreeCen database contents data (Records tab on main application) which are number of total pieces present, number of pieces online and new pieces
class Freecen2ContentsController < ApplicationController
  require 'chapman_code'
  require 'freecen_constants'
  skip_before_action :require_login

  def county_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @county_description = params[:county_description]
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    @all_places = @freecen2_contents.records[@chapman_code][:total][:places].sort
    @from_main_records_page = 'NO'
    location_href = 'location.href= "/freecen2_contents/place_index/?from_main_records_page=''' + @from_main_records_page + '''&county_description=''' + @county_description + '''&place_description='
    # place names containing & or + cause problems in hrefs, so call javascript replace_chars to replace with unicode value (function is in the view)
    @location = location_href + '" + replace_chars(this.value)'
  end


  def place_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @view_place_records = params["view_place_records"]
    if @view_place_records.present?
      @place_description = @view_place_records["place_description"]
      @county_description = @view_place_records["county_description"]
      @from_main_records_page = "YES"
    else
      @county_description = params[:county_description]
      @place_description = params[:place_description]
      @from_main_records_page = params[:from_main_records_page]
    end
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    @key_place = Freecen2Content.get_place_key(@place_description)
    @place_id = @freecen2_contents.records[@chapman_code][@key_place][:total][:place_id]
    Freecen2PlaceUniqueName.find_by(freecen2_place_id: @place_id).present? ? @has_names = true : @has_names = false
  end

  def piece_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @last_id = BSON::ObjectId.from_time(@interval_end)
    @county_description = params[:county_description]
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    @census = params[:census_year]
    @place_description = params[:place_description]
    @place_id = params[:place_id]
    @from_main_records_page = params[:from_main_records_page]
    if params[:census_year] == 'all'
      @census = 'All Years'
      @place_pieces = Freecen2Piece.where(_id: { '$lte' => @last_id },freecen2_place_id: @place_id)
    else
      @census = params[:census_year]
      @place_pieces = Freecen2Piece.where(_id: { '$lte' => @last_id },freecen2_place_id: @place_id, year: @census)
    end
  end

  def place_names
    @county_description = params[:county_description]
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    @year = params[:census_year]
    @place_description = params[:place_description]
    @from_main_records_page = params[:from_main_records_page]
    @place = Freecen2Place.find_by(chapman_code: @chapman_code, place_name: @place_description)
    @place_unique_names = Freecen2PlaceUniqueName.find_by(freecen2_place_id: @place.id)
    @first_names = @place_unique_names.unique_forenames[@year]
    @last_names = @place_unique_names.unique_surnames[@year]
    @first_names_cnt = @first_names.count
    @last_names_cnt = @last_names.count
    if params[:name_type] == "Surnames" ||  params[:name_type].to_s.empty?
      @unique_names = @last_names
      @name_type = 'Surnames'
    else
      @unique_names = @first_names
      @name_type = 'Forenames'
    end
    if params[:first_letter].present?
      @first_letter = params[:first_letter]
    else
      @first_letter = 'All'
    end
    @unique_names, @remainder = Freecen2Content.letterize(@unique_names)
  end

  def for_view_places_form
    p "AEV HERE"
    if params["view_place_records"].present?
      county_description = params[:view_place_records][:county_description]
      chapman_code = ChapmanCode.code_from_name(county_description)
      id = session[:contents_id]
      freecen2_contents = Freecen2Content.find_by(id: id)
      county_places = freecen2_contents.records[county][:total][:places]
      respond_to do |format|
        format.json do
          render json: county_places
        end
      end
    end
  end

  def create
    @freecen2_content = Freecen2Content.new(freecen2_content_params)
    @freecen2_content.save
    if @freecen2_content.errors.any?
      flash[:notice] = 'There were errors'
      redirect_to(new_freecen2_content_path(@freecen2_content)) && return
    end
    redirect_to(freecen2_content_path(@freecen2_content))
  end

  def new
    @freecen2_content = Freecen2Content.new
  end

  def index
    @freecen2_contents = Freecen2Content.order(interval_end: :desc).first
    @interval_end = @freecen2_contents.interval_end
    session[:contents_id] = @freecen2_contents.id
    @all_counties = @freecen2_contents.records[:total][:counties].sort!
    p "AEV100 Controller Index"
    #
    @places_for_county = ['Castle Cary','Milborne Port']
    #
    @location = 'location.href= "/freecen2_contents/county_index/?county_description=" + this.value'
  end


  private

  def freecen2_content_params
    params.require(:freecen2_content).permit!
  end
end
