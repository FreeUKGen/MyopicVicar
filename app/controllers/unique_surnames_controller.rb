class UniqueSurnamesController < ApplicationController
  skip_before_action :require_login

  def index
    @surnames = UniqueSurnames.where("name LIKE '%" + params[:prefix] + "%'")
  end
end
