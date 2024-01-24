require "rails_helper"

RSpec.describe MyActionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/my_actions").to route_to("my_actions#index")
    end

    it "routes to #new" do
      expect(get: "/my_actions/new").to route_to("my_actions#new")
    end

    it "routes to #show" do
      expect(get: "/my_actions/1").to route_to("my_actions#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/my_actions/1/edit").to route_to("my_actions#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/my_actions").to route_to("my_actions#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/my_actions/1").to route_to("my_actions#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/my_actions/1").to route_to("my_actions#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/my_actions/1").to route_to("my_actions#destroy", id: "1")
    end
  end
end
