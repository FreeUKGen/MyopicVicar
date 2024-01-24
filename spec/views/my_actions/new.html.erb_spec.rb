require 'rails_helper'

RSpec.describe "my_actions/new", type: :view do
  before(:each) do
    assign(:my_action, MyAction.new(
      name: "MyString",
      description: "MyText",
      child_of: ""
    ))
  end

  it "renders new my_action form" do
    render

    assert_select "form[action=?][method=?]", my_actions_path, "post" do

      assert_select "input[name=?]", "my_action[name]"

      assert_select "textarea[name=?]", "my_action[description]"

      assert_select "input[name=?]", "my_action[child_of]"
    end
  end
end
