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
    @all_districts = @freecen2_contents.records[@chapman_code][:total][:districts]
    @district = Freecen2District.new  # needed for simple_form_for in view
    location_href = 'location.href= "/freecen2_contents/district_index/?county_description=''' + @county_description+ '''&district_description='
    # district names containing & or + cause problems in hrefs, so call javascript replace_chars to replace with unicode value (function is in the view)
    @location = location_href + '" + replace_chars(this.value)'
  end

  def district_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @county_description = params[:county_description]
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    @district_description = params[:district_description]
    @key_district =  Freecen2Content.get_district_key(@district_description)
    @all_places = @freecen2_contents.records[@chapman_code][@key_district][:total][:places]
    @place = Freecen2Place.new  # needed for simple_form_for in view
    location_href = 'location.href= "/freecen2_contents/place_index/?county_description=''' + @county_description + '''&district_description='''  + @district_description + '''&key_district='''  + @key_district + '''&place_description='
    # place names containing & or + cause problems in hrefs, so call javascript replace_chars to replace with unicode value (function is in the view)
    @location = location_href + '" + replace_chars(this.value)'
  end

  def place_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @county_description = params[:county_description]
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    @district_description = params[:district_description]
    @key_district =  Freecen2Content.get_district_key(@district_description)
    @place_description = params[:place_description]
    @key_place = Freecen2Content.get_place_key(@place_description)
    @place_id = @freecen2_contents.records[@chapman_code][@key_district][@key_place][:total][:place_id]
  end

  def piece_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @last_id = BSON::ObjectId.from_time(@interval_end)
    @county_description = params[:county_description]
    @chapman_code = params[:chapman_code]
    @district_description = params[:district_description]
    @census = params[:census_year]
    @place_description = params[:place_description]
    @place_id = params[:place_id]
    if params[:census_year] =='all'
      @census = 'All Years'
      @place_pieces = Freecen2Piece.where(_id: { '$lte' => last_id },freecen2_place_id: @place_id)
    else
      @census = params[:census_year]
      @place_pieces = Freecen2Piece.where(_id: { '$lte' => @last_id },freecen2_place_id: @place_id, year: @census)
    end
  end

  def place_names
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @last_id = BSON::ObjectId.from_time(@interval_end)
    @county_description = params[:county_description]
    @chapman_code = params[:chapman_code]
    @district_description = params[:district_description]
    @year = params[:census_year]
    @place_description = params[:place_description]
    @place_id = params[:place_id]
    @first_names, @last_names = Freecen2Content.unique_names_place(@place_id)
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

  def create
    @freecen2_content = Freecen2Content.new(freecen2_content_params)
    @freecen2_content.save
    if @freecen2_content.errors.any?
      flash[:notice] = 'There were errors'
      redirect_to(new_freecen2_content_path(@freecen2_content)) && return
    end
    redirect_to(freecen2_content_path(@freecen2_content))
  end

  def edit
    @freecen2_content = Freecen2Content.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @freecen2_content.blank?
  end

  def new
    @freecen2_content = Freecen2Content.new
  end

  def index
    @freecen2_contents = Freecen2Content.order(interval_end: :desc).first
    @interval_end = @freecen2_contents.interval_end
    session[:contents_id] = @freecen2_contents.id
    @all_counties = @freecen2_contents.records[:total][:counties].sort!
    @county = County.new  # needed for simple_form_for in view
    @location = 'location.href= "/freecen2_contents/county_index/?county_description=" + this.value'
  end

  def show
    @freecen2_content = Freecen2Content.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @freecen2_content.blank?
  end

  def update
    @freecen2_content = Freecen2Content.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No such record') && return if @freecen2_content.blank?
    proceed = @freecen2_content.update_attributes(freecen2_content_params)
    unless proceed
      flash[:notice] = 'There were errors'
      redirect_to(edit_freecen2_content_path(@freecen2_content)) && return
    end
    redirect_to(freecen2_content_path(@freecen2_content))
  end

  private

  def freecen2_content_params
    params.require(:freecen2_content).permit!
  end
end