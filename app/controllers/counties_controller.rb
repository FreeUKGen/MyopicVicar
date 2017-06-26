class CountiesController < ApplicationController

  require 'county'

  def display
    get_user_info_from_userid
    @counties = County.all.order_by(chapman_code: 1)
    render :action => :index
  end

  def edit
    load(params[:id])
    get_userids_and_transcribers
  end

  def index
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?
    @counties = County.all.order_by(chapman_code: 1)
  end

  def load(id)
    @county = County.id(id).first
    if @county.nil?
      go_back("county",id)
    end
  end

  def new
    @first_name = session[:first_name]
    @county = County.new
    get_userids_and_transcribers
  end

  def selection
    get_user_info(session[:userid],session[:first_name])
    session[:county] = 'all' if @user.person_role == 'system_administrator'
    case
    when params[:county] == "Browse counties"
      @counties = County.all.order_by(chapman_code: 1)
      render "index"
      return
    when params[:county] == "Create county"
      redirect_to :action => 'new'
      return
    when params[:county] == "Edit specific county"
      counties = County.all.order_by(chapman_code: 1)
      @counties = Array.new
      counties.each do |county|
        @counties << county.chapman_code
      end
      @location = 'location.href= "select?act=edit&county=" + this.value'
    when params[:county] == "Show specific county"
      counties = County.all.order_by(chapman_code: 1)
      @counties = Array.new
      counties.each do |county|
        @counties << county.chapman_code
      end
      @location = 'location.href= "select?act=show&county=" + this.value'
    else
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return
    end
    @prompt = 'Select county'
    params[:county] = nil
    @county = session[:county]
  end

  def select
    get_user_info(session[:userid],session[:first_name])
    case
    when !params[:county].nil?
      if params[:county] == ""
        flash[:notice] = 'Blank cannot be selected'
        redirect_to :back
        return
      else
        county = County.where(:chapman_code => params[:county]).first
        if params[:act] == "show"
          redirect_to county_path(county)
          return
        else
          redirect_to edit_county_path(county)
          return
        end
      end
    else
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return
    end
  end

  def show
    load(params[:id])
    person = UseridDetail.userid(@county.county_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil?
    person = UseridDetail.userid(@county.previous_county_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? || person.person_forename.nil?
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?
  end

  def update
    load(params[:id])
    my_params = params[:county]
    params[:county] = @county.update_fields_before_applying(my_params)
    @county.update_attributes(county_params)
    if @county.errors.any?
      flash[:notice] = "The change to the county was unsuccessful"
      render :action => 'edit'
      return
    else
      flash[:notice] = "The change to the county was successful"
      redirect_to counties_path
    end
  end

  private
  def county_params
    params.require(:county).permit!
  end


end
