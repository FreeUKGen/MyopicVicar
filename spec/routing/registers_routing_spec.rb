require "spec_helper"

describe RegistersController do
  describe "routing" do

    it "routes to #index" do
      get("/registers").should route_to("registers#index")
    end

    it "routes to #new" do
      get("/registers/new").should route_to("registers#new")
    end

    it "routes to #show" do
      get("/registers/1").should route_to("registers#show", :id => "1")
    end

    it "routes to #edit" do
      get("/registers/1/edit").should route_to("registers#edit", :id => "1")
    end

    it "routes to #create" do
      post("/registers").should route_to("registers#create")
    end

    it "routes to #update" do
      put("/registers/1").should route_to("registers#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/registers/1").should route_to("registers#destroy", :id => "1")
    end

  end
end
