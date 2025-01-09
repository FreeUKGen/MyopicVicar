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

  # how to display pages - need to have a page which displays/renders sub-pages, and a routine which does both the
  # 'on this page' island and the 'overall structure' island. Less elegant than I hoped for, but not being allowed
  # to do multiple renders within a block means the rendering can't be driven from an array or hash.
  def default_page
    render 'new_index'
  end

  # This approach fails, because Rails refuses to allow multiple/repeated render commands in a single block.
  # Instead we declare each page explicitly, with a series of render commands to pull in its sub-pages.
  # Sadly, this means that page content and island-generating hashes have to be kept in sync by hand:
  def process_help_hash hashname
    hashname.each do |id, heading|
      display_subpage id
    end
  end

  def display_subpage subpage
    render partial: subpage
  end
end
