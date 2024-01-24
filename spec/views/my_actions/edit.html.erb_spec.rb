require 'rails_helper'

RSpec.describe "my_actions/edit", type: :view do
  before(:each) do
    @my_action = assign(:my_action, MyAction.create!(
      name: "MyString",
      description: "MyText",
      child_of: ""
    ))
  end

  it "renders the edit my_action form" do
    render

    assert_select "form[action=?][method=?]", my_action_path(@my_action), "post" do

      assert_select "input[name=?]", "my_action[name]"

      assert_select "textarea[name=?]", "my_action[description]"

      assert_select "input[name=?]", "my_action[child_of]"
    end
  end
end
