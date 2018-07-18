class SourcesController < ApplicationController
  require 'freereg_options_constants'
  
  def access_image_server
    @user = get_user
    (session[:manage_user_origin] != 'manage county' && session[:chapman_code].nil?) ? chapman_code = 'all': chapman_code = session[:chapman_code]
    website = Source.create_manage_image_server_url(@user.userid,@user.person_role,chapman_code)  
    redirect_to website and return
  end

  def create
    display_info

    source = Source.where(:register_id=>params[:source][:register_id]).first
    register = source.register

    source = Source.new(source_params)
    source.save

    if source.errors.any? then
      flash[:notice] = 'Addition of Source "'+params[:source][:source_name]+'" was unsuccessful'
      redirect_to :back
    else
      register.sources << source
      register.save

      flash[:notice] = 'Addition of Source "'+params[:source][:source_name]+'" was successful'
      redirect_to index_source_path(source.register)     
    end
  end

  def destroy
    display_info
    get_user_info(session[:userid],session[:first_name])

    if ['system_administrator', 'data_managers'].include? @user.person_role
      source = Source.id(params[:id]).first

      begin
        source.destroy
        flash[:notice] = 'Deletion of "'+source[:source_name]+'" was successful'
        session.delete(:source_id)
        redirect_to index_source_path(source.register)      

      rescue Mongoid::Errors::DeleteRestriction
        logger.info "Logged Error for Source Delete"
        logger.debug source.source_name+' is not empty'
        redirect_to(:back, :notice=> source.source_name+' IS NOT EMPTY, CAN NOT BE DELETED')
      end 

    else
      flash[:notice] = 'Only system_administrator and data_manager is allowed to delete source'
      redirect_to :back
    end
  end

  def display_info
    @source = Source.find(:id=>session[:source_id]) if !session[:source_id].nil?
    @register = Register.find(:id=>session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    @church = Church.find(session[:church_id])
    @church_name = session[:church_name]
    @county =  session[:county]
    @place_name = session[:place_name]
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = get_user
  end

  def edit
    display_info

    @source = Source.id(params[:id]).first

    redirect_to(:back, :notice => 'Attempted to edit a non_existent Source') and return if @source.nil?
  end

  def flush
    display_info

    @source = Source.id(params[:id]).first
    go_back("source#flush", params[:id]) and return if @source.nil?

    @source_id = Source.get_propagate_source_list(@source)
  end

  def index
    display_info
    params[:id] = session[:register_id] if params[:id].nil?

    @source = Source.where(:register_id=>params[:id]).all
    go_back("source#index",params[:id]) and return if @source.nil?

    case @source.count
      when 0
        redirect_to(:back, :notice => 'No Source under this register')
      when 1
        case @source.first.source_name
          when 'Image Server'
            redirect_to source_path(:id=>@source.first.id)
          when 'other server1'
            redirect_to :controller=>'server1', :action=>'show', :source_name=>'other server1'
          when 'other server2'
#            redirect_to :controller=>'server2', :action=>'show', :source_name=>'other server1'
          else
            redirect_to(:back, :notice => 'Something wrong')
        end
    end
  end

  def initialize_status
    display_info

    allow_initialize = ImageServerGroup.check_all_images_status_before_initialize_source(params[:id])

    redirect_to(:back, :notice=>'Source can be initialized only when all image groups status is unset') and return if not allow_initialize
  end

  def load(source_id)
    @source = Source.id(source_id).first

    if @source.nil?
      go_back("source", source_id)
    else
      session[:source_id] = @source.id
      @register = @source.register
      @register_type = RegisterType.display_name(@register.register_type)
      session[:register_id] = @register.id
      session[:register_name] = @register_type
      @church = @register.church
      @church_name = @church.church_name
      session[:church_name] = @church_name
      session[:church_id] = @church.id
      @place = @church.place
      session[:place_id] = @place.id
      @place_name = @place.place_name
      session[:place_name] = @place_name
      @county = @place.county
      session[:county] = @county
      @user = get_user
    end
  end

  def new 
    display_info

    @source_new = Source.new
    name_array = Source.where(:register_id=>session[:register_id]).pluck(:source_name)
    go_back("source#new", params[:id]) and return if name_array.nil?

    @list = FreeregOptionsConstants::SOURCE_NAME - name_array
  end

  def show
    # sessions used for breadcrumb
    session[:image_group_filter] = params[:image_group_filter] if !params[:image_group_filter].nil?
    session[:assignment_filter_list] = params[:assignment_filter_list] if !params[:assignment_filter_list].nil?
    # indicate image group display comes from Source or filters under 'All Sources' directly
    session[:from_source] = true

    load(params[:id])
    go_back("source#show", params[:id]) and return if @source.nil?
  end

  def update
    source = Source.where(:id=>params[:id]).first
    go_back("source#update", params[:id]) and return if source.nil?

    if source_params[:choice] == '1'                        # to propagate Source
      Source.update_for_propagate(params)
      flash[:notice] = 'Update of source was successful'
    elsif !source_params[:initialize_status].nil?           # to initialize Source
      ImageServerGroup.initialize_all_images_status_under_source(params[:id], source_params[:initialize_status])
      flash[:notice] = 'Successfully initialized source'
    else                                                    # to edit Source
      params[:source].delete(:choice)
      source.update_attributes(source_params)
      flash[:notice] = 'Update of source was successful'
    end

    flash.keep(:notice)
    redirect_to index_source_path(source.register)
  end

  private
  def source_params
    params.require(:source).permit!
  end

end
