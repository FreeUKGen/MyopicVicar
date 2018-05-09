class GapsController < ApplicationController

  def create
    display_info
    source = Source.id(params[:gap][:source_id]).first

    gap = Gap.new(gap_params)
    gap.save

    if gap.errors.any? then
      flash[:notice] = 'Addition of Gap failed: ' + gap.errors.full_messages.join("<br/>").html_safe
      redirect_to :back
    else
      flash[:notice] = 'Addition of Gap was successful'
      redirect_to index_gap_path(source)     
    end
  end

  def display_info
    if session[:source_id].present?
      @source = Source.find(session[:source_id])
    end

    session[:source_id] = @source.id
    session[:register_id] = @source.register_id
    @register = Register.find(session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    session[:church_id] = @register.church_id
    @church = Church.find(session[:church_id])
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @church_name = session[:church_name]
    @place = @church.place #id?
    @place_name = @place.place_name
    session[:place_name] = @place_name
    @county =  @place.county
    @chapman_code = @place.chapman_code
    session[:county] = @county
    session[:chapman_code] = @syndicate if session[:chapman_code].nil?
    @user = cookies.signed[:userid]
  end

  def destroy
    display_info

    gap = Gap.where(:id=>params[:id]).first
    source = gap.source

    gap.destroy

    flash[:notice] = 'Deletion of GAP was successful'
    redirect_to index_gap_path(source)  
  end

  def edit
    display_info

    @gap = Gap.where(:id=>params[:id]).first

    redirect_to(:back, :notice => 'Attempted to edit a non_esxistent Image Group') and return if @gap.nil?
  end

  def index
    display_info
    params[:id] = session[:source_id] if params[:id].nil?

    @gap = Gap.where(:source_id=>params[:id]).all
    go_back("source#index",params[:id]) and return if @source.nil?

    redirect_to gap_path(:id=>@gap.first.id) if @gap.count == 1
  end

  def new 
    display_info
    @reason = GapReason.all.pluck(:reason).sort_by{|x| x}

    @gap = Gap.new
  end

  def show
    display_info

    @gap = Gap.where(:id=>params[:id])

    if @gap.nil?
      redirect_to(:back, :notice => 'Source does not have any GAP')
    else
      @gap = @gap.first
    end
  end

  def update
    gap = Gap.where(:id=>params[:id]).first

    gap.update_attributes(gap_params)

    flash[:notice] = 'Update of GAP was successful'
    redirect_to index_gap_path(gap.source)
  end

  private
  def gap_params
    params.require(:gap).permit! if params[:_method] != 'put'
  end

end
