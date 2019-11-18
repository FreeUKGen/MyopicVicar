class EmbargoReasonsController < ApplicationController
  def create
    redirect_back(fallback_location: { action: 'index' }, notice: 'You must enter a field ') && return if params[:embargo_reason].blank?

    @reason = EmbargoReason.new(denomination_params)
    @reason.save
    redirect_back(fallback_location: { action: 'index' }, notice: "The creation of the new reason was unsuccessful because #{@reason.errors.messages}") && return if @reason.errors.any?
    flash[:notice] = 'The creation of the new reason was successful'
    redirect_to action: 'index'
  end

  def edit
    @reason = EmbargoReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The embargo reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless @user.person_role == 'system_administrator' || @user.person_role == 'executive_director'
  end

  def destroy
    @reason = EmbargoReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The embargo reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless @user.person_role == 'system_administrator' || @user.person_role == 'executive_director'

    @reason = EmbargoReason.delete
    flash[:notice] = 'The destruction of the embargo reason was successful'
    redirect_to action: 'index'
  end

  def index
    get_user_info_from_userid
    @reasons = EmbargoReason.all.order_by(reason: 1)
  end

  def new
    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless @user.person_role == 'system_administrator' || @user.person_role == 'executive_director'

    @reason = EmbargoReason.new
  end

  def show
    @reason = EmbargoReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The embargo reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
  end

  def update
    @reason = EmbargoReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The embargo reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
    proceed = @reason.update_attributes(embargo_reason_params)
    redirect_back(fallback_location: { action: 'index' }, notice: "The embargo reason update was unsuccessful; #{@reason.errors.messages}") && return unless proceed

    flash[:notice] = 'The update of the embargo reason was successful'
    redirect_to action: 'index'
  end

  private

  def embargo_reason_params
    params.require(:embargo_reason).permit!
  end
end
