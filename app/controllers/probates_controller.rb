class ProbatesController < ApplicationController
  skip_before_action :require_login

  def new
    @probate = Probate.new
    #@probate.Death.build
    #@probate.Event.build
  end

  def index
    @probate = Probate.new
    #@probate.Death.build
    #@probate.Event.build
  end

  def show
    @search_id = params[:search_id]
    @search = params[:search_id].present? ? true : false
    @person_id = params[:person_id]
    @search_query = params[:search_query]
    @search_record = Probate.where('PersonId': @person_id).first
    @death = Death.where('PersonId': @person_id).first
    @event = Event.where('PersonId': @person_id).first
    respond_to do |format|
      format.html
      format.pdf
      format.json { render json: self.to_json}
    end
  end

  def edit
    @probate = Probate.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: probates_path, notice: 'The probate record was not found') && return if @probate.blank?
    @person_id = @probate[:PersonId]
    @death = Death.where('PersonId': @person_id).first
    @event = Event.where('PersonId': @person_id).first
    @executors = Executor.where('PersonId': @person_id)
    #@probate.build

    render :edit
  end

  def update
    @probate = Probate.find(params[:id])
    @probate.build
    if @probate.update()
      #flash[:success] = 'Probate successfully updated'
      redirect_back(fallback_location: probates_path, notice: 'Probate successfully updated') && return
    end
    #render :update
  end

end

