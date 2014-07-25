require "spec_helper"

describe PlaceCachesController do
  describe "routing" do

    it "routes to #index" do
      get("/place_caches").should route_to("place_caches#index")
    end

    it "routes to #new" do
      get("/place_caches/new").should route_to("place_caches#new")
    end

    it "routes to #show" do
      get("/place_caches/1").should route_to("place_caches#show", :id => "1")
    end

    it "routes to #edit" do
      get("/place_caches/1/edit").should route_to("place_caches#edit", :id => "1")
    end

    it "routes to #create" do
      post("/place_caches").should route_to("place_caches#create")
    end

    it "routes to #update" do
      put("/place_caches/1").should route_to("place_caches#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/place_caches/1").should route_to("place_caches#destroy", :id => "1")
    end

  end
end
