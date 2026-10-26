# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home page", type: :feature do
  it "loads the root page and shows the search form" do
    visit root_path

    expect(page).to have_http_status(:ok)
    expect(page).to have_current_path(root_path)
    expect(page).to have_selector("h1", text: "Search our Parish Registers")

    within("form") do
      expect(page).to have_field("Surname")
      expect(page).to have_field("Forename(s)")
      expect(page).to have_field("First year")
      expect(page).to have_field("Last year")
      expect(page).to have_field("County")
      expect(page).to have_button("Search")
    end
  end
end
