require "spec_helper"

describe FreeregContentsController do
  describe "routing" do

    it "routes to #index" do
      get("/freereg_contents").should route_to("freereg_contents#index")
    end

    it "routes to #new" do
      get("/freereg_contents/new").should route_to("freereg_contents#new")
    end

    it "routes to #show" do
      get("/freereg_contents/1").should route_to("freereg_contents#show", :id => "1")
    end

    it "routes to #edit" do
      get("/freereg_contents/1/edit").should route_to("freereg_contents#edit", :id => "1")
    end

    it "routes to #create" do
      post("/freereg_contents").should route_to("freereg_contents#create")
    end

    it "routes to #update" do
      put("/freereg_contents/1").should route_to("freereg_contents#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/freereg_contents/1").should route_to("freereg_contents#destroy", :id => "1")
    end

  end
end
