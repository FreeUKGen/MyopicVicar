require "spec_helper"

describe FreecenDwellingsController do
  describe "routing" do

    it "routes to #index" do
      get("/freecen_dwellings").should route_to("freecen_dwellings#index")
    end

    it "routes to #new" do
      get("/freecen_dwellings/new").should route_to("freecen_dwellings#new")
    end

    it "routes to #show" do
      get("/freecen_dwellings/1").should route_to("freecen_dwellings#show", :id => "1")
    end

    it "routes to #edit" do
      get("/freecen_dwellings/1/edit").should route_to("freecen_dwellings#edit", :id => "1")
    end

    it "routes to #create" do
      post("/freecen_dwellings").should route_to("freecen_dwellings#create")
    end

    it "routes to #update" do
      put("/freecen_dwellings/1").should route_to("freecen_dwellings#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/freecen_dwellings/1").should route_to("freecen_dwellings#destroy", :id => "1")
    end

  end
end
