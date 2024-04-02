class UniqueForenamesController < ApplicationController
  skip_before_action :require_login

  def index
    @term_in_context = "^"+params[:term]
    @forenames = UniqueForename.where({"Name": {"$regex": @term_in_context, "$options": "i"}}).limit(10)
    render :json => get_search_names_hash(@forenames)
  end

  def show
    @forenames = UniqueForename.where({"Name": {"$regex": @term_in_context}})
  end

  # this returns JSON as an array of names:
  def get_search_names_hash(names)
    output_array = []
    names.each do |name|
      capitalised_name = name.Name.split.map!(&:capitalize)
      format_name = capitalised_name.map{|n| n.split('-').map!(&:capitalize).join('-')}
      output_array << format_name.join(' ')
    end unless names.nil? or names.blank?
    output_array
  end

end

