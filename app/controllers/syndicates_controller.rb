# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class SyndicatesController < ApplicationController
  def create
    @syndicate = Syndicate.new(syndicate_params)
    redirect_back(fallback_location: syndicates_path, notice: 'The Syndicate Name must not contain Question Marks') && return if @syndicate.syndicate_code.include? '?'

    @syndicate.add_syndicate_to_coordinator(params[:syndicate][:syndicate_code],params[:syndicate][:syndicate_coordinator])
    @syndicate.upgrade_syndicate_coordinator_person_role(params[:syndicate][:syndicate_coordinator])
    @syndicate.save
    redirect_back(fallback_location: edit_manage_syndicate_path(@syndicate), notice: "The creation of the Syndicate was unsuccessful because: #{@syndicate.errors.full_messages}") && return if @syndicate.errors.any?

    flash[:notice] = 'The addition of the Syndicate was successful'
    redirect_to syndicates_path
  end

  def destroy
    load(params[:id])
    redirect_back(fallback_location: syndicates_path, notice: 'The Syndicate was not found') && return if @syndicate.blank?

    if UseridDetail.where(syndicate: @syndicate.syndicate_code).exists?
      flash[:notice] = 'The deletion of the Syndicate cannot proceed as it still has members.'
      redirect_to syndicate_path(@syndicate)
    else
      @syndicate.remove_syndicate_from_coordinator
      @syndicate.downgrade_syndicate_coordinator_person_role
      @syndicate.destroy
      flash[:notice] = 'The deletion of the Syndicate was successful'
      redirect_to syndicates_path
    end
  end

  def display
    @syndicates = Syndicate.all.order_by(syndicate_code: 1)
    get_user_info_from_userid
    render action: :index
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: syndicates_path, notice: 'The Syndicate was not found') && return if @syndicate.blank?

    userids_and_transcribers
  end

  def userids_and_transcribers
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    case
    when @user.person_role == 'system_administrator' || @user.person_role == 'volunteer_coordinator'
      @userids = UseridDetail.all.order_by(userid_lower_case: 1)
    when  @user.person_role == 'country_cordinator'
      @userids = UseridDetail.where(syndicate: @user.syndicate).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
    when  @user.person_role == 'county_coordinator'
      @userids = UseridDetail.where(syndicate: @user.syndicate).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
    when  @user.person_role == 'sydicate_coordinator'
      @userids = UseridDetail.where(syndicate: @user.syndicate).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
    else
      @userids = @user
    end #end case
    @people = []
    @userids.each do |ids|
      @people << ids.userid
    end
  end

  def index
    if session[:userid].blank?
      redirect_to '/', notice: 'You are not authorised to use these facilities'
    end
    get_user_info_from_userid
    @syndicates = Syndicate.all.order_by(syndicate_code: 1)
  end

  def load(id)
    @first_name = session[:first_name]
    @syndicate = Syndicate.find(id)
    @first_name = session[:first_name]
    get_user_info_from_userid
  end

  def new
    get_user_info_from_userid
    @syndicate = Syndicate.new
    userids_and_transcribers
  end

  def select
    get_user_info_from_userid
    redirect_back(fallback_location: syndicates_path, notice: 'Blank cannot be selected') && return if params[:synd] == '' || params[:synd].blank?

    syndicate = Syndicate.where(syndicate_code: params[:synd]).first
    if params[:action] == 'show'
      redirect_to syndicate_path(syndicate)
    else
      redirect_to edit_syndicate_path(syndicate)
    end
  end

  def selection
    get_user_info_from_userid
    session[:syndicate] = 'all' if @user.person_role == 'system_administrator'
    case params[:synd]
    when 'Browse syndicates'
      @syndicates = Syndicate.all.order_by(syndicate_code: 1)
      render 'index'
    when 'Create syndicate'
      redirect_to(action: :new) && return
    when 'Show specific syndicate'
      syndicates = Syndicate.all.order_by(syndicate_code: 1)
      @syndicates = []
      syndicates.each do |synd|
        @syndicates << synd.syndicate_code
      end
      @location = 'location.href= "select?action=show&synd=" + this.value'
    when 'Edit specific syndicate'
      syndicates = Syndicate.all.order_by(syndicate_code: 1)
      @syndicates = []
      syndicates.each do |synd|
        @syndicates << synd.syndicate_code
      end
      @location = 'location.href= "select?action=edit&synd=" + this.value'
    else
      redirect_back(fallback_location: syndicates_path, notice: 'Invalid Option') && return
    end
    @prompt = 'Select syndicate'
    @syndicate = session[:syndicate]
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: syndicates_path, notice: 'The Syndicate was not found') && return if @syndicate.blank?

    person = UseridDetail.where(userid: @syndicate.syndicate_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname if person.present?
    person = UseridDetail.where(userid: @syndicate.previous_syndicate_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname if person.present? && person.person_forename.present? && person.person_surname.present?
  end

  def update
    load(params[:id])
    redirect_back(fallback_location: syndicates_path, notice: 'The Syndicate was not found') && return if @syndicate.blank?

    my_params = params[:syndicate]
    redirect_back(fallback_location: edit_manage_syndicate_path(@syndicate), notice: 'The Syndicate Name must not contain Question Marks') && return if my_params[:syndicate_code].include? '?'

    params[:syndicate] = @syndicate.update_fields_before_applying(my_params)
    @syndicate.update_attributes(syndicate_params)
    redirect_back(fallback_location: edit_manage_syndicate_path(@syndicate), notice: "The update of the Syndicate was unsuccessful because: #{@syndicate.errors.full_messages}") && return if @syndicate.errors.any?

    @syndicate.update_attributes(changing_name: false) if @syndicate.changing_name
    flash[:notice] = 'The change to the Syndicate was successful'
    redirect_to syndicates_path
  end

  private

  def syndicate_params
    params.require(:syndicate).permit!
  end
end
