require "spec_helper"

describe Freecen1VldFilesController do
  describe "routing" do

    it "routes to #index" do
      get("/freecen1_vld_files").should route_to("freecen1_vld_files#index")
    end

    it "routes to #new" do
      get("/freecen1_vld_files/new").should route_to("freecen1_vld_files#new")
    end

    it "routes to #show" do
      get("/freecen1_vld_files/1").should route_to("freecen1_vld_files#show", :id => "1")
    end

    it "routes to #edit" do
      get("/freecen1_vld_files/1/edit").should route_to("freecen1_vld_files#edit", :id => "1")
    end

    it "routes to #create" do
      post("/freecen1_vld_files").should route_to("freecen1_vld_files#create")
    end

    it "routes to #update" do
      put("/freecen1_vld_files/1").should route_to("freecen1_vld_files#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/freecen1_vld_files/1").should route_to("freecen1_vld_files#destroy", :id => "1")
    end

  end
end
