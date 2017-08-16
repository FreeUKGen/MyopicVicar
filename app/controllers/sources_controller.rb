class SourcesController < ApplicationController
  require 'freereg_options_constants'
 
  skip_before_filter :require_login, only: [:show]

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
    else
      flash[:notice] = 'Only system_administrator and data_manager is allowed to delete source'
      redirect_to :back
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
    end
  end

  def index
    display_info
    params[:id] = session[:register_id] if params[:id].nil?
    @source = Source.where(:register_id=>params[:id]).all

    if @source.nil?
      go_back("source#index",params[:id])
    else
      case @source.count
        when 0
          flash[:notice] = 'No Source under this register'
          redirect_to :back
        when 1
          case @source.first.source_name
            when 'Image Server'
              redirect_to source_path(:id=>source.first.id)
            when 'other server1'
#              redirect_to :controller=>'server1', :action=>'show', :source_name=>'other server1'
            when 'other server2'
#              redirect_to :controller=>'server2', :action=>'show', :source_name=>'other server1'
            else
              flash[:notice] = 'Somthing wrong'
              redirect_to :back
          end
       end
    end
  end

  def load(source_id)
    @source = Source.id(source_id).first
    if @source.nil?
      go_back("source",source_id)
    else
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
      @county =  session[:county]
      @place_name = @place.place_name
      session[:place_name] = @place_name
      get_user_info_from_userid
    end
  end

  def new 
    display_info
    @source = Source.new
    name_array = Source.where(:register_id=>session[:register_id]).pluck(:source_name)

    if name_array.nil?
      go_back("source#new",params[:id])
    else
      @list = FreeregOptionsConstants::SOURCE_NAME - name_array
    end
  end

  def propagate
    display_info
    @source = Source.new
    @source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    source1 = Source.where(:id=>params[:id]).first
    if source1.nil?
      go_back("source#propagate",params[:id])
    else
      place = source1.register.church.place
      place_id = Place.where(:chapman_code=>place.chapman_code).pluck(:id, :place_name).to_h

      church_id = Church.where(:place_id=>{'$in'=>place_id.keys}).pluck(:id, :place_id, :church_name)
      church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| church_id.each{|k,v,w| h[k] << v << w}}

      register_id = Register.where(:church_id=>{'$in'=>church_id.keys}).pluck(:id, :church_id, :register_type)
      register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| register_id.each{|k,v,w| h[k] << v << w}}

      x = Source.where(:register_id=>{'$in'=>register_id.keys}, :source_name=>source1.source_name).pluck(:id, :register_id).to_h
    
      x.each do |k1,v1|
        @source_id['Place: '+place_id[church_id[register_id[v1][0]][0]]+', Church: '+church_id[register_id[v1][0]][1]+' - '+RegisterType.display_name(register_id[v1][1])] = k1
      end

      respond_to do |format|
        format.js
        format.json
        format.html
      end
    end
  end

  def show
    load(params[:id])
    display_info
    @source = Source.id(params[:id]).first

    go_back("source#show",params[:id]) if @source.nil?
  end

  def update
    source = Source.where(:id=>params[:id]).first

    if source.nil?
      go_back("source#update",params[:id])
    else
      if source_params[:choice] == '1'  # propagate checkbox is selected
        notes = source_params[:notes]
        original_form_type = source_params[:original_form][:type]
        original_form_name = source_params[:original_form][:name]
        original_owner = source_params[:original_owner]
        creating_institution = source_params[:creating_institution]
        holding_institution = source_params[:holding_institution]
        restrictions_on_use_by_creating_institution = source_params[:restrictions_on_use_by_creating_institution]
        restrictions_on_use_by_holding_institution = source_params[:restrictions_on_use_by_holding_institution]
        open_data = source_params[:open_data]
        url = source_params[:url]
        source_list = source_params[:propagate][:source_id]
        source_list << params[:id]

        Source.where(:id=>{'$in'=>source_list}).update_all(:notes=>notes, :original_form=>{:type=>original_form_type, :name=>original_form_name}, :original_owner=>original_owner, :creating_institution=>creating_institution, :holding_institution=>holding_institution, :restrictions_on_use_by_creating_institution=>restrictions_on_use_by_creating_institution, :restrictions_on_use_by_holding_institution=>restrictions_on_use_by_holding_institution, :open_data=>open_data, :url=>url)
      else
        params[:source].delete(:choice)
        source.update_attributes(source_params)
      end

      flash[:notice] = 'Update of source was successful'
      flash.keep(:notice)
      redirect_to index_source_path(source.register)
    end
  end

  private
  def source_params
    params.require(:source).permit!
  end

end
