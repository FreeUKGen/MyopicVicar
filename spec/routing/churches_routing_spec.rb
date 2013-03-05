require "spec_helper"

describe ChurchesController do
  describe "routing" do

    it "routes to #index" do
      get("/churches").should route_to("churches#index")
    end

    it "routes to #new" do
      get("/churches/new").should route_to("churches#new")
    end

    it "routes to #show" do
      get("/churches/1").should route_to("churches#show", :id => "1")
    end

    it "routes to #edit" do
      get("/churches/1/edit").should route_to("churches#edit", :id => "1")
    end

    it "routes to #create" do
      post("/churches").should route_to("churches#create")
    end

    it "routes to #update" do
      put("/churches/1").should route_to("churches#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/churches/1").should route_to("churches#destroy", :id => "1")
    end

  end
end
