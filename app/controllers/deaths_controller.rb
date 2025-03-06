# frozen_string_literal: true

class DeathsController < ApplicationController
skip_before_action :require_login

def new
  @death = Death.new
end

end
