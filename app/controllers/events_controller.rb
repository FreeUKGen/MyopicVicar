# frozen_string_literal: true

class EventsController < ApplicationController
  skip_before_action :require_login

  def new
    @event = Event.new
  end
end
