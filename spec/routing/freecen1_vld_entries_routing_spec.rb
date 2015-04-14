require "spec_helper"

describe Freecen1VldEntriesController do
  describe "routing" do

    it "routes to #index" do
      get("/freecen1_vld_entries").should route_to("freecen1_vld_entries#index")
    end

    it "routes to #new" do
      get("/freecen1_vld_entries/new").should route_to("freecen1_vld_entries#new")
    end

    it "routes to #show" do
      get("/freecen1_vld_entries/1").should route_to("freecen1_vld_entries#show", :id => "1")
    end

    it "routes to #edit" do
      get("/freecen1_vld_entries/1/edit").should route_to("freecen1_vld_entries#edit", :id => "1")
    end

    it "routes to #create" do
      post("/freecen1_vld_entries").should route_to("freecen1_vld_entries#create")
    end

    it "routes to #update" do
      put("/freecen1_vld_entries/1").should route_to("freecen1_vld_entries#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/freecen1_vld_entries/1").should route_to("freecen1_vld_entries#destroy", :id => "1")
    end

  end
end
