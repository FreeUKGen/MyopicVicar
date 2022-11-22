class UniqueForenamesController < ApplicationController
  skip_before_action :require_login

  def index
    @forenames = UniqueForenames.where("name LIKE '%" + params[:prefix] + "%'")
    render formats: [:json, :xml, :html]
  end

  def show
    @forenames = UniqueForenames.where("name LIKE '%" + params[:prefix] + "%'")
  end

  # we want something like to return JSON when that is the :format specified:
  def get_search_names_hash(names)
    original = {}
    names.search_names.each do |name|
      original[name._id] = JSON.parse(name.to_json(except: :_id))
    end
    original
  end

end

