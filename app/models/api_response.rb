# frozen_string_literal: true

class ApiResponse
  include Mongoid::Document
  #include Mongoid::Timestamps

  field :request, type: Array, default: []
  field :total, type: Integer
  field :matches, type: Array, default: []
  field :start, type: Integer
  field :limit, type: Integer

end
