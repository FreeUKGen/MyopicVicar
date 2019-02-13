require 'spec_helper'

describe "test basic functionality" do


  it "checks the search page loads" do
    visit root_path
    
    p 'foo'
  end
  
  it "runs a FreeREG search" do
    # set to FreeREG
    # process a single csv file
    visit root_path
    
    # verify this is the search form
    # verify this is FreeREG

    page.fill_in 'last_name', :with => 'first'
    page.fill_in 'first_name', :with => 'first'
  #  page.fill_in 'chapman_code', :with => 'KEN'
    select 'KEN', :from => 'search_query_chapman_codes'
 #   page.fill_in "search_query_chapman_codes_hidden", :with => 'KEN'
    page.find('#search_query_chapman_codes').set('KEN') #no ID on these fields so we have to use a selector
    click_button 'Search'
    expect(page).to have_content("05 Nov 1653")
    click_link 'Row 1'
    expect(page).to have_content("Person forename")
    expect(page).to have_content("05 Nov 1653")
    
  
  
    
  end

end
