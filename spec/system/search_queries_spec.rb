require 'rails_helper'

RSpec.describe 'SearchQueries', type: :system do
  before do
    driven_by(:rack_test)
  end

  it 'does a baptism search query' do
    visit root_path

    expect(page).to have_content 'Search our Parish Registers'
    expect(page).to have_content 'Search fields'

    fill_in 'last_name', with: 'pile'
    fill_in 'start_year', with: '1730'
    fill_in 'end_year', with: '1850'
    choose 'ba'
    click_button 'Search'

    expect(page).to have_content 'We found'
    # expect(page).to have_content 'No results found'
  end
end
