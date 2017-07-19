class IsSourcesController < ApplicationController
 
  skip_before_filter :require_login, only: [:show]

  def create
    @ig = IsSource.where(:register_id=>params[:is_source][:register_id]).pluck(:ig)
    register = Register.where(:id=>params[:is_source][:register_id]).first

    if not @ig.include?(params[:is_source][:ig])
      is_source = IsSource.new(is_source_params)

      is_source.save!
      register.is_sources << is_source
      register.save!

      if is_source.errors.any? then
        flash[:notice] = 'The addition of Image Group "'+params[:is_source][:ig]+'" was unsuccessful'
        redirect_to :back
      else
        flash[:notice] = 'The addition of Image Group "'+params[:is_source][:ig]+'" was successful'
        redirect_to is_source_path(register, :register_id=>register.id)
      end
    else
      flash[:notice] = 'Sub Group "'+params[:is_source][:ig]+'" already exist'
      redirect_to new_is_source_path(register, :register_id=>register.id)
    end
  end

  def destroy
    is_source = IsSource.id(params[:id]).first
    return_location = is_source.register
    is_image = IsImage.where(:is_source_id=>is_source.id).count

    if is_image == 0
      is_source.destroy
      flash[:notice] = 'The deletion of IG "'+is_source[:ig]+'" was successful'
      redirect_to is_source_path(return_location, :register_id=>return_location.id)      
    else
      flash[:notice] = 'IG "'+is_source[:ig]+'" includes images, can not be deleted'
      redirect_to is_source_path(return_location, :register_id=>return_location.id)
    end
  end

  def display_info
    @register = Register.find(:id=>session[:register_id])
    @church = Church.find(session[:church_id])
    @church_name = session[:church_name]
    @county =  session[:county]
    @place_name = session[:place_name]
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = cookies.signed[:userid]
  end

  def edit
    @is_source = IsSource.id(params[:id])
    display_info
    get_userids_and_transcribers

    if @is_source.nil?
      flash[:notice] = 'Attempting to edit a non_esxistent source'
      redirect_to :back
      return
    else
      flash.clear
    end
  end

  def error
  end

def get_userids_and_transcribers
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?
    case
    when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator'
      @userids = UseridDetail.where(:active=>true).order_by(userid_lower_case: 1)
    when  @user.person_role == 'country_cordinator'
      @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
    when  @user.person_role == 'county_coordinator'
      @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
    when  @user.person_role == 'sydicate_coordinator'
      @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
    else
      @userids = @user
    end

    @people =Array.new
    @userids.each do |ids|
      @people << ids.userid
    end
  end

  def index
    @is_page = IsPage.source_id(@is_source.id).all.order_by(ig: 1)
  end

  def new 
    @is_source = IsSource.new
    @ig = IsSource.where(:register_id=>params[:id]).pluck(:ig)
    display_info
  end

  def show
    if params[:register_id].nil?
      @is_source = IsSource.id(params[:id]).sort_by{|x| x.ig.downcase}
    else
      @is_source = IsSource.where(:register_id=>params[:register_id]).sort_by{|x| x.ig.downcase}
    end

    if @is_source.present?
      get_user_info_from_userid
      display_info

      render 'index'
    else
      flash[:notice] = "This register does not have any IG in the datebase."
      redirect_to :back
    end
  end

  def update
    is_source = IsSource.id(params[:id]).first

# if status = in_progress, check if :transcriber is null, if not, :assign_date = current_date, if yes, refuse update
    if is_source[:ig] == params[:is_source][:ig]
      is_source.update_attributes(is_source_params)
      flash[:notice] = 'Update of Image Group "'+params[:is_source][:ig]+'" was successful'
      redirect_to is_source_path(is_source, :register_id=>is_source[:register_id])      
    else
      ig = IsSource.where(:register_id=>is_source.register_id, :ig=>params[:is_source][:ig]).first

      if ig.nil?
        is_source.update_attributes(is_source_params)

        flash[:notice] = 'Update of Image Group "'+params[:is_source][:ig]+'" was successful'
        redirect_to is_source_path(is_source, :register_id=>is_source[:register_id])
      else
        flash[:notice] = 'Image Group "'+params[:is_source][:ig]+'" already exist'
        redirect_to :back
      end
    end
  end

  private
  def is_source_params
    params.require(:is_source).permit!
  end

end
