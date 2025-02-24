class ProbatesController < ApplicationController
  skip_before_action :require_login

  def show
    respond_to do |format|
      format.html
      format.pdf
      format.json { render json: self.to_json}
    end
  end
end

