# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :require_login

  def show_page
    if params[:page].present?
      current_page = params[:page]
    else
      current_page = 'intro'
    end
    render(current_page)
  end
end
