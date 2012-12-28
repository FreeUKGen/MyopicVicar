require "spec_helper"

describe ChurchNamesController do
  describe "routing" do

    it "routes to #index" do
      get("/church_names").should route_to("church_names#index")
    end

    it "routes to #new" do
      get("/church_names/new").should route_to("church_names#new")
    end

    it "routes to #show" do
      get("/church_names/1").should route_to("church_names#show", :id => "1")
    end

    it "routes to #edit" do
      get("/church_names/1/edit").should route_to("church_names#edit", :id => "1")
    end

    it "routes to #create" do
      post("/church_names").should route_to("church_names#create")
    end

    it "routes to #update" do
      put("/church_names/1").should route_to("church_names#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/church_names/1").should route_to("church_names#destroy", :id => "1")
    end

  end
end
