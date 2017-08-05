class DenominationsController < ApplicationController
 
  def create
    if params[:denomination].blank?
      flash[:notice] = 'You must enter a field '
      redirect_to :back
      return
    end
    @denomination  = Denomination.new(denomination_params)
    @denomination.save
    if @denomination.errors.any?
      flash[:notice] = "The creation of the new denomination was unsuccessful because #{@denomination.errors.messages}"
      get_userids_and_transcribers
      redirect_to :back
      return
    end #errors
    flash[:notice] = 'The creation of the new denomination was successful'
    redirect_to :action => 'index'
    return
  end

  def destroy
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      go_back("denomination",params[:id])
    end
    @denomination.delete
    flash[:notice] = 'The destruction of the denomination was successful'
    redirect_to :action => 'index'
    return
  end

  def edit
    get_user_info_from_userid
    reject_assess(@user,"Denomination") unless @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      go_back("denomination",params[:id])
    end
  end

  def index
    get_user_info_from_userid
    @denominations = Denomination.all.order_by(denomination: 1)
  end

  def new
    get_user_info_from_userid
    reject_assess(@user,"Denomination") unless @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
    @denomination = Denomination.new
  end
  def show
    get_user_info_from_userid
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      go_back("denomination",params[:id])
    end
  end

  def update
    get_user_info_from_userid
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      go_back("denomination",params[:id])
    end
    @denomination.update_attributes(denomination_params )
    flash[:notice] = 'The creation of the new denomination was successful'
    redirect_to :action => 'index'
    return
  end

  private
  def denomination_params
    params.require(:denomination).permit!
  end

end
