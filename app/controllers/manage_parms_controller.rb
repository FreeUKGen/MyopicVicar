class ManageParmsController < ApplicationController
	before_action :set_current_user

	def select_year
    session[:page] = request.original_url
    session[:manage_user_origin] = 'manage parm'
    get_user_info_from_userid
    @parms = [1831, 1841, 1851, 1861, 1871, 1881, 1891, 1901, 1911]
    @options = @parms
    @location = 'location.href= "/manage_parms/"+ this.value +/new'
  end

	def get_dat_files_of_census_year
		@errors = session[:parm_errors] if session[:parm_errors].present?
		get_user_info_from_userid
		@freecen1_fixed_dat_files = Freecen1FixedDatFile.where(year: params[:year])
	end

  def upload_files
  	@parm = ManageParm.new(manage_parm_params)
  	@parm.import
  	raise parm.errors.any?.inspect

  	if parm.import
  		flash[:notice] = "File loaded successfully."
		  load_parms = ManageParm.load_parm_files(params[:parm_files], params[:year])
	 	else
	 		session[:parm_errors] = parm.errors
	 		flash[:notice] = "File cannot be loaded. Please try again"
		end
		redirect_to get_dat_files_of_census_year_manage_parm_path(year: params[:year])
  end

  def index
    @manage_parms = ManageParm.where(chapman_code: session[:chapman_code]).all
  end

  def new
    @manage_parm = ManageParm.new
  end

  def create
  	@manage_parm = ManageParm.new(manage_parm_params)
  	@manage_parm.import
    if @manage_parm.save #@manage_parm.errors.any?
    	@manage_parm.load_parm_files
    	flash[:notice] = 'Parm file uploaded was successful'
      redirect_to manage_parms_path
    else
    	flash[:notice] = 'Parm file uploaded was unsuccessful. Please fix the errors and try again'
      render action: 'edit'
    end
  end

  def process_new_parm_file
  	@parm_file = ManageParm.where(id: params[:id]).first
  	@parm_file.update_attributes(process: 1)
  	@parm_file.run_new_file_processer
  	@parm_file.update_attributes(process: 1)
  end

  private

  def set_current_user
  	get_user_info_from_userid
  end

  def manage_parm_params
    params.require(:manage_parm).permit(:year, :userid, :chapman_code, :parm_file, :file_name)
  end
end
