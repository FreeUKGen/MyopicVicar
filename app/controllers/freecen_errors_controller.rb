class FreecenErrorsController < ApplicationController
  skip_before_filter :require_login

  def index
    @freecen_error_list = FreecenError.get_errors_list
  end
end
