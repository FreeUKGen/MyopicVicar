class ManageParmsController < ApplicationController
	def select_year
    session[:page] = request.original_url
    session[:manage_user_origin] = 'manage parm'
    get_user_info_from_userid
    @parms = [1831, 1841, 1851, 1861, 1871, 1881, 1891, 1901, 1911]
    @options = @parms
    @location = 'location.href= "/manage_parms/" + this.value +/get_dat_files_of_census_year/'
  end

	def get_dat_files_of_census_year
		@errors = session[:parm_errors] if session[:parm_errors].present?
		get_user_info_from_userid
		@freecen1_fixed_dat_files = Freecen1FixedDatFile.where(year: params[:year])
	end

  def upload_files
  	@parm = ManageParm.new(year: params[:year], userid: params[:user], file_name: params[:parm_files].original_filename, chapman_code: params[:chapman_code])
  	@parm.save
  	if @parm.save
		  load_parms = ManageParm.load_parm_files(params[:parm_files], params[:year])
	 	else
	 		session[:parm_errors] = @parm.errors
	 		flash[:notice] = "File cannot be loaded. Please try again"#{}"Files Uploaded! invalid_filenames: #{load_parms[:invalid_files]}, Number of valid files: #{load_parms[:valid_files_count]}"
		end
		redirect_to get_dat_files_of_census_year_manage_parm_path(year: params[:year])
  end


  def index
    @parms = ManageParm.all
  end
end
