class SourcesController < ApplicationController
 
  skip_before_filter :require_login, only: [:show]

  def create
  end

  def destroy
  end

  def display_info
    @register = Register.find(:id=>session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
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
    display_info
    @source = Source.id(params[:id]).first

    if @source.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent Source'
      redirect_to :back
      return
    end
  end

  def index
    display_info
    @source = Source.where(:register_id=>params[:id])
  end

  def new 
  end

  def show
    display_info
    @source = Source.where(:register_id=>params[:id])
  end

  def update
    source = Source.where(:id=>params[:id]).first

    source.update_attributes(source_params)
    flash[:notice] = 'Update of source was successful'
    redirect_to index_source_path(source.register)     
  end

  private
  def source_params
    params.require(:source).permit!
  end

end
