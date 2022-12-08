class UniqueSurnamesController < ApplicationController
  skip_before_action :require_login

  def index
    @surnames = UniqueSurnames.where("name LIKE '" + params[:term] + "%'")
    render :json => get_search_names_hash(@surnames)
  end

  # when we want to return JSON as an array of names, something like this could be handy:
  def get_search_names_hash(names)
    output_array = []
    names.each do |name|
      output_array << name.Name
    end
    output_array
  end

end
