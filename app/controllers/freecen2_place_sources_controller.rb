class Freecen2PlaceSourcesController < ApplicationController

  def create
    redirect_back(fallback_location: { action: 'index' }, notice: 'You must enter a source ') && return if params[:freecen2_place_source].blank?

    @source = Freecen2PlaceSource.new(freecen2_place_source_params)
    @source.save
    redirect_back(fallback_location: { action: 'index' }, notice: "The creation of the new source was unsuccessful because #{@source.errors.messages}") && return if @source.errors.any?

    flash[:notice] = 'The creation of the new source was successful'
    redirect_to action: 'index'
  end

  def destroy
    @source = Freecen2PlaceSource.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The source was not found ') && return if @source.blank?

    @source.delete
    flash[:notice] = 'The destruction of the source was successful'
    redirect_to action: 'index'
  end

  def edit
    @source = Freecen2PlaceSource.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The source was not found ') && return if @source.blank?

    get_user_info_from_userid
    reject_access(@user, 'Place Source Edit') unless @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
  end

  def index
    get_user_info_from_userid
    sources_array = Freecen2PlaceSource.all.map { |rec| [rec.source, rec.source.downcase] }
    sources_array_sorted = sources_array.sort_by { |entry| entry[1] }
    @sources = []
    sources_array_sorted.each do |entry|
      @sources << Freecen2PlaceSource.find_by(source: entry[0])
    end
  end

  def new
    get_user_info_from_userid
    reject_access(@user, 'Place Source Create') unless @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
    @source = Freecen2PlaceSource.new
  end

  def show
    @source = Freecen2PlaceSource.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The source was not found ') && return if @source.blank?

    get_user_info_from_userid
  end

  def update
    @source = Freecen2PlaceSource.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The source was not found ') && return if @source.blank?

    get_user_info_from_userid
    redirect_back(fallback_location: { action: 'index' }, notice: 'The source field cannot be empty') && return if freecen2_place_source_params[:source].blank?

    proceed = @source.update_attributes(freecen2_place_source_params)
    redirect_back(fallback_location: { action: 'index' }, notice: "The source update was unsuccessful; #{@source.errors.messages}") && return unless proceed

    flash[:notice] = 'The update of the source was successful'
    redirect_to action: 'index'
  end

  private

  def freecen2_place_source_params
    params.require(:freecen2_place_source).permit!
  end
end
