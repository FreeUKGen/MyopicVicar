require "spec_helper"

describe AliasPlaceChurchesController do
  describe "routing" do

    it "routes to #index" do
      get("/alias_place_churches").should route_to("alias_place_churches#index")
    end

    it "routes to #new" do
      get("/alias_place_churches/new").should route_to("alias_place_churches#new")
    end

    it "routes to #show" do
      get("/alias_place_churches/1").should route_to("alias_place_churches#show", :id => "1")
    end

    it "routes to #edit" do
      get("/alias_place_churches/1/edit").should route_to("alias_place_churches#edit", :id => "1")
    end

    it "routes to #create" do
      post("/alias_place_churches").should route_to("alias_place_churches#create")
    end

    it "routes to #update" do
      put("/alias_place_churches/1").should route_to("alias_place_churches#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/alias_place_churches/1").should route_to("alias_place_churches#destroy", :id => "1")
    end

  end
end
