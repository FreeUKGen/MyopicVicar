require 'rails_helper'

RSpec.describe "my_actions/index", type: :view do
  before(:each) do
    assign(:my_actions, [
      MyAction.create!(
        name: "Name",
        description: "MyText",
        child_of: ""
      ),
      MyAction.create!(
        name: "Name",
        description: "MyText",
        child_of: ""
      )
    ])
  end

  it "renders a list of my_actions" do
    render
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
    assert_select "tr>td", text: "".to_s, count: 2
  end
end
