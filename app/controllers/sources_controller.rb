class SourcesController < ApplicationController
  require 'freereg_options_constants'
 
  skip_before_filter :require_login, only: [:show]

  def create
    display_info
    source = Source.where(:register_id=>params[:source][:register_id]).first
    register = source.register

    source = Source.new(source_params)
    source.save!

    if source.errors.any? then
      flash[:notice] = 'Addition of Source "'+params[:source][:source_name]+'" was unsuccessful'
      redirect_to :back
    else
      register.sources << source
      register.save!

      flash[:notice] = 'Addition of Source "'+params[:source][:source_name]+'" was successful'
      redirect_to index_source_path(source.register)     
    end
  end

  def destroy
    display_info
    source = Source.id(params[:id]).first
    return_location = source.register
    image_server_group = ImageServerGroup.where(:source_id=>params[:id]).count

    if image_server_group == 0
      source.destroy
      flash[:notice] = 'Deletion of "'+source[:source_name]+'" was successful'
      redirect_to index_source_path(return_location)      
    else
      flash[:notice] = '"'+source[:source_name]+'" contains image groups, can not be deleted'
      redirect_to index_source_path(return_location)
    end
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

    case @source.count
      when 0
        flash[:notice] = 'No Source under this register'
        redirect_to :back
      when 1
        case @source.first.source_name
          when 'Image Server'
            redirect_to :action=>'show'
          when 'other server1'
#            redirect_to :controller=>'server1', :action=>'show'
          when 'other server2'
#            redirect_to :controller=>'server2', :action=>'show'
          else
            flash[:notice] = 'Somthing wrong'
            redirect_to :back
        end
    end
  end

  def new 
    display_info
    @source = Source.new
    name_array = Source.where(:register_id=>session[:register_id]).pluck(:source_name)
    @list = FreeregOptionsConstants::SOURCE_NAME - name_array
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
