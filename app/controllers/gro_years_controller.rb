class GroYearsController < ApplicationController
  skip_before_action :require_login

  def index
    @years = GroYears.where("year LIKE \"" + params[:term] + "%\"")
    render :json => get_search_names_hash(@years)
  end

  def show
    @years = GroYears.where("year LIKE '%" + params[:term] + "%'")
  end

  # when we want to return JSON as an array of names, something like this could be handy:
  def get_search_names_hash(years)
    output_array = []
    years.each do |year|
      output_array << year.year
    end
    output_array
  end

end
