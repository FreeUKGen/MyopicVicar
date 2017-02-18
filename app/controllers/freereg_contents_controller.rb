class FreeregContentsController < ApplicationController
  require 'chapman_code'
  require 'freereg_options_constants'
  skip_before_filter :require_login
  skip_before_action :verify_authenticity_token
  def create
    case
    when params.present? && params[:freereg_content].present? && params[:freereg_content][:chapman_codes].present?#params[:commit] == "Select"
      @freereg_content = FreeregContent.new(freereg_content_params)
      @chapman_code = params[:freereg_content][:chapman_codes][1]
      session[:chapman_code] = @chapman_code
      if  @freereg_content.save
        @county = ChapmanCode.name_from_code(@chapman_code)
        session[:county] = @county
        redirect_to freereg_contents_path
        return
      else
        @freereg_content.chapman_codes = []
        @options = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::CODES))
        render :new
      end
    when params[:action] == "create"
      proceed = FreeregContent.check_how_to_proceed(params[:freereg_content])
      case proceed
      when "dual"
        flash[:notice] = "Choose a place or a letter \u2014; you cannot choose both."
        redirect_to freereg_contents_path and return
      when "no option"
        flash[:notice] = "Choose a place or a letter \u2014; you must choose something."
        redirect_to freereg_contents_path and return
      when "place"
        redirect_to freereg_content_path(params[:freereg_content][:place]) and return
      when "character"
        session[:character] = params[:freereg_content][:character]
        redirect_to action: :select_places and return
      end
    end
  end

  def index
    session[:character] = nil
    if session[:chapman_code].present? && ChapmanCode::values.include?(session[:chapman_code])
      @show_alphabet = FreeregContent.determine_if_selection_needed(session[:chapman_code],session[:character])
      @page = FreeregContent.get_header_information(session[:chapman_code])
      @coordinator = County.coordinator_name(session[:chapman_code])
      @records = FreeregContent.number_of_records_in_county(session[:chapman_code])
      if @show_alphabet == 0
        @places = FreeregContent.get_records_for_display(session[:chapman_code])
      else
        @freereg_content = FreeregContent.new
        @options = FreeregOptionsConstants::ALPHABETS[@show_alphabet]
        @places = FreeregContent.get_places_for_display(session[:chapman_code])
      end
      session[:show_alphabet] = @show_alphabet
      @county = session[:county]
      @chapman_code = session[:chapman_code]
      @character = session[:character]
    else
      flash[:notice] = "You have not selected a county"
      redirect_to :action => :new
    end
  end

  def new
    session[:character] = nil
    session[:county] = nil
    session[:chapman_code] = nil
    @freereg_content = FreeregContent.new
    @options = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::CODES))
  end

  def place
    @place = Place.id(params[:id]).first
    if @place.present?
      @character =  nil
      @county = @place.place_name
      @chapman_code = @place.chapman_code
      @coordinator = County.coordinator_name(@chapman_code)
      @place_name = @place.place_name
      @names = @place.get_alternate_place_names
      @decade = @place.daterange
      @transcribers = @place.transcribers
      @contributors = @place.contributors
    else
      flash[:notice] = "Non existent place has been selected."
      redirect_to :back and return
    end
  end

  def select_places
    @character = session[:character]
    @show_alphabet = session[:show_alphabet]
    @county = session[:county]
    @chapman_code = session[:chapman_code]
    if @chapman_code.present? &&  @county.present? && @character.present?
      @coordinator = County.coordinator_name(@chapman_code)
      @page = FreeregContent.get_header_information(@chapman_code)
      allplaces = Place.chapman_code(@chapman_code).not_disabled.data_present.all.order_by(place_name: 1)
      @places = Array.new
      allplaces.each do |place|
        @places << place if place.place_name =~  /^[#{@character}]/i
      end
      @records = FreeregContent.number_of_records_in_county(@chapman_code)
      render  '_show_body'
      return
    else
      flash[:notice] = "Problem with your selection."
      redirect_to :action => 'new' and return
    end

  end


  def show
    if params[:id].present?
      @county = session[:county]
      @chapman_code = session[:chapman_code]
      @character = session[:character]
      if session[:chapman_code].present? && ChapmanCode::values.include?(session[:chapman_code])
        @place = Place.chapman_code(@chapman_code).place(params[:id]).not_disabled.data_present.first
        @page = FreeregContent.get_header_information(session[:chapman_code])
        @coordinator = County.coordinator_name(session[:chapman_code])
        @records = FreeregContent.number_of_records_in_county(session[:chapman_code])
        if @place.blank?
          flash[:notice] = "You appear to have selected an invalid place"
          redirect_to :action => :new
          return
        end
      else
        flash[:notice] = "You have not selected a county"
        redirect_to :action => :new
        return
      end
    else
      flash[:notice] = "You do not appear to have selected a place"
      redirect_to :action => :new
      return
    end
  end

  def show_church
    @church = Church.id(params[:id]).first
    if @church.nil?
      flash[:notice] = "No church was selected while reviewing the content; you will need to start again"
      if session[:county].present?
        redirect_to :index
        return
      else
        redirect_to :action => :new
        return
      end
    end
    @county = session[:county]
    @character =  session[:character]
    @chapman_code = session[:chapman_code]
    @place_name = @church.place.place_name
    @place = @church.place
    @church_name = @church.church_name
    @decade = @church.daterange
    @transcribers = @church.transcribers
    @contributors = @church.contributors
    @registers = Register.where(:church_id => params[:id]).order_by(:record_types.asc, :register_type.asc, :start_year.asc).all
  end

  def show_place
    @character =  session[:character]
    @county = session[:county]
    @chapman_code = session[:chapman_code]
    @place = Place.chapman_code(@chapman_code).place(params[:id]).not_disabled.data_present.first
    @coordinator = County.coordinator_name(@chapman_code)
    if @place.present?
      @place_name = @place.place_name
      @names = @place.get_alternate_place_names
      @decade = @place.daterange
      @transcribers = @place.transcribers
      @contributors = @place.contributors
    else
      flash[:notice] = "Non existent place has been selected."
      redirect_to :action => 'new' and return
    end
  end

  def show_register
    @register = Register.id(params[:id]).first
    if @register.nil?
      flash[:notice] = "No register was selected while reviewing the content; you will need to start again"
      if session[:county].present?
        redirect_to :action => :alphabet
        return
      else
        redirect_to :action => :new
        return
      end
    end
    @church  = @register.church
    if  @church.present?
      @place = @church.place
      @county = session[:county]
      @character =  session[:character]
      @files_id = Array.new
      @place_name = @place.place_name
      @register_name = @register.register_name
      @register_name = @register.alternate_register_name if @register_name.nil?
      @church_name = @church.church_name
      @register_type = RegisterType.display_name(@register.register_type)
      @decade = @register.daterange
      @transcribers = @register.transcribers
      @contributors = @register.contributors
    else
      flash[:notice] = "The register has no church; you will need to start again"
      redirect_to :back and return
    end
  end


  private
  def freereg_content_params
    params.require(:freereg_content).permit!
  end
end
