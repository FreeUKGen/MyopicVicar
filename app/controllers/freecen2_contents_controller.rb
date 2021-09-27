# Manages the collection of FreeCen database contents data (Records tab on main application) which are number of total pieces present, number of pieces online and new pieces
class Freecen2ContentsController < ApplicationController
  require 'chapman_code'
  require 'freecen_constants'
  skip_before_action :require_login

  def county_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = session[:interval_end]
    if params[:county_description] == nil
      @county_description = session[:county]
    else
      @county_description = params[:county_description]
      session[:county] = @county_description
    end
    @chapman_code = ChapmanCode.code_from_name(@county_description)
    session[:chapman_code] = @chapman_code
    get_districts_for_selection(session[:chapman_code],session[:interval_end])
    @district = Freecen2District.new
    # district names containing & or + cause problems in hrefs, so call javascript replace_chars to replace with unicode value (function is in the view)
    @location = 'location.href= "/freecen2_contents/district_index/?district_description=" + replace_chars(this.value)'
  end

  def district_index
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = session[:interval_end]
    @county_description = session[:county]
    @chapman_code = session[:chapman_code]
    @district_description = params[:district_description]
    @key_district = Freecen2Content.get_district_key(@district_description)
    session[:key_district] = @key_district
    session[:district_description] = @district_description
  end

  def piece_index
    @county_description = session[:county]
    @chapman_code = session[:chapman_code]
    @district_description = session[:district_description]
    @census = params[:census_year]
    session[:census] = @census

    @interval_end = session[:interval_end]
    @last_id = BSON::ObjectId.from_time(@interval_end)
    @piece_ids = []
    if params[:census_year] =='all'
      @census = 'All Years'
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        @district_recs = Freecen2District.where(name: @district_description, chapman_code: @chapman_code,year: census)
        @district_recs.each do |district|
          Freecen2Piece.freecen2_district_id(district.id).each do |piece|
            if piece.id <= @last_id
              @piece_ids << piece.id
            end
          end
        end
      end
      @district_pieces = Freecen2Piece.where(_id: { '$in' => @piece_ids}).order_by(name: :asc, number: :asc, year: :asc)
    else
      @census = params[:census_year]
      @district_recs = Freecen2District.where(name: @district_description, chapman_code: @chapman_code, year: @census)
      @district_recs.each do |district|
        Freecen2Piece.freecen2_district_id(district.id).each do |piece|
          if piece.id <= @last_id
            @piece_ids << piece.id
          end
        end
      end
      @district_pieces = Freecen2Piece.where(_id: { '$in' => @piece_ids}).order_by(name: :asc, number: :asc)
    end
  end

  def piece_names
    @county_description = session[:county]
    @chapman_code = session[:chapman_code]
    @district_description = session[:district_description]
    @census = session[:census]
    @interval_end = session[:interval_end]
    if params[:contents_piece_id] == nil
      @piece_id = session[:contents_piece_id]
    else
      @piece_id = params[:contents_piece_id]
      session[:contents_piece_id] = @piece_id
    end
    @piece = Freecen2Piece.find_by(_id: @piece_id)
    @piece_number = @piece.number
    @piece_name = @piece.name
    @piece_year = @piece.year
    @first_names = []
    @last_names = []
    @search_records = SearchRecord.where(freecen2_piece_id: @piece._id)
    @search_records.each do |search_rec|
      search_rec.search_names.each do |name|
        @first_names << name.first_name.upcase
        @last_names << name.last_name.upcase
      end
    end
    @first_names = @first_names.uniq
    @last_names = @last_names.uniq
    @first_names_cnt = @first_names.count
    @last_names_cnt = @last_names.count
    @first_names.sort!
    @last_names.sort!
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

  def get_counties_for_selection
    @all_counties = []
    stats = Freecen2Content.order(interval_end: :desc).first
    county_keys = stats.records.keys
    county_keys.delete_at(0) # total
    county_keys.each do |chapman_code|
      @all_counties.push(ChapmanCode.name_from_code(chapman_code)) unless stats.records[chapman_code][:total][:pieces] == 0
    end
    @all_counties.sort!
  end

  def get_districts_for_selection(chapman_code,time)
    @all_districts = Freecen2Piece.distinct_districts(chapman_code, time).sort!
  end

  def new
    @freecen2_content = Freecen2Content.new
  end

  def index
    @freecen2_contents = Freecen2Content.order(interval_end: :desc).first
    @interval_end = @freecen2_contents.interval_end
    session[:interval_end] = @interval_end
    session[:contents_id] = @freecen2_contents.id
    get_counties_for_selection
    @county = County.new
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
