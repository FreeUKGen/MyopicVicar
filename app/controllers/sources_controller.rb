class SourcesController < ApplicationController
 
  skip_before_filter :require_login, only: [:show]

  def create
  end

  def destroy
  end

  def display_info
    @register = Register.find(:id=>session[:register_id])
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
    @is_page = IsPage.source_id(@is_source.id).all.order_by(ig: 1)
  end

  def new 
  end

  def show
p "============================source show============================="    
    display_info
    @source = Source.where(:register_id=>params[:id])

    case @source.count
      when 0
        flash[:notice] = 'This register does not have any source in the database'
        redirect_to :back
      when 1    # when only one source_name, display that source
        case @source.first.source_name
          when 'Image Server'
#            redirect_to image_server_group_path(:id=>@source.first.id)
          when 'Other Server1'   # leave for other servers
          when 'Other Server2'
          else
            flash[:notice] = 'something wrong'
            redirect_to :back
        end
      else    # when more than one source name, list source_name
    end
  end

  def update
  end

  private
  def source_params
    params.require(:source).permit!
  end

end
