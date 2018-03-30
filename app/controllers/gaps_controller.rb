class GapsController < ApplicationController

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
    @user = cookies.signed[:userid]
  end

  def edit
  end


  def index
    display_info
    params[:id] = session[:source_id] if params[:id].nil?

    @gap = Gap.where(:source_id=>params[:id]).all
    go_back("source#index",params[:id]) and return if @source.nil?

    case @gap.count
      when 0
        redirect_to(:back, :notice => 'No GAP under this Source')
      when 1
        redirect_to gap_path(:id=>@gap.first.id)
    end
  end


  private
  def gap_params
    params.require(:gap).permit! if params[:_method] != 'put'
  end

end
