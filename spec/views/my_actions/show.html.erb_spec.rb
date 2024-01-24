require 'rails_helper'

RSpec.describe "my_actions/show", type: :view do
  before(:each) do
    @my_action = assign(:my_action, MyAction.create!(
      name: "Name",
      description: "MyText",
      child_of: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
