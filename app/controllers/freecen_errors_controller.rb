class FreecenErrorsController < ApplicationController
  skip_before_filter :require_login

  def index
    @freecen_error_list = FreecenError.get_errors_list
    @freecen_error_files_list = FreecenError.get_pieces_not_loaded_list
  end
end
