class UniqueForenamesController < ApplicationController
  skip_before_action :require_login

  def index
    @forenames = UniqueForenames.where("name LIKE '%" + params[:prefix] + "%'")
    render :json => @forenames
  end

  def show
    @forenames = UniqueForenames.where("name LIKE '%" + params[:prefix] + "%'")
  end

  # when we want to return JSON as an array of names, something like this could be handy:
  def get_search_names_hash(names)
    original = {}
    names.search_names.each do |name|
      original[name._id] = JSON.parse(name.to_json(except: :_id))
    end
    original
  end

end

