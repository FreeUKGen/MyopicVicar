class CountriesController < ApplicationController
  
  def create
    @country = Country.new(country_params)
    @country.save
    if @country.errors.any?
      flash[:notice] = "The addition of the Country was unsuccessful"
      render :action => 'edit'
      return
    else
      flash[:notice] = "The addition of the Country was successful"
      #Syndicate.change_userid_fields(params)
      redirect_to countries_path
    end
  end

  def edit
    load(params[:id])
    get_userids_and_transcribers
  end


  def index
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?
    @countries = Country.all.order_by(country_code: 1)
  end

  def load(id)
    @first_name = session[:first_name]
    @country = Country.id(id).first
    if @country.nil?
      go_back("country",id)
    end
  end

  def new
    @first_name = session[:first_name]
    @country = Country.new
    get_userids_and_transcribers
  end

  def show
    load(params[:id])
    person = UseridDetail.where(:userid => @country.country_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil?
    person = UseridDetail.where(:userid => @country.previous_country_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? || person.person_forename.nil?
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?
  end

  def update
    load(params[:id])
    my_params = params[:country]
    params[:country] = @country.update_fields_before_applying(my_params)
    @country.update_attributes(country_params)
    if @country.errors.any?

      flash[:notice] = "The change to the country was unsuccessful"
      render :action => 'edit'
      return
    else
      flash[:notice] = "The change to the country was successful"

      redirect_to countries_path
    end

  end




  private
  def country_params
    params.require(:country).permit!
  end



end
