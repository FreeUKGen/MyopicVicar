class UniqueSurnamesController < ApplicationController
  skip_before_action :require_login

  def index
    require 'unique_surnames'
    @term_in_context = "^"+params[:term]
    @surnames = UniqueSurname.where({"Name": {"$regex": @term_in_context, "$options": "i"}}).limit(10)
    render :json => get_search_names_hash(@surnames)
  end

  # when we want to return JSON as an array of names, something like this could be handy:
  def get_search_names_hash(names)
    output_array = []
    names.each do |name|
      output_array << name.Name.split.map!(&:capitalize).join(' ')
    end unless names.nil? or names.blank?
    output_array
  end

end
