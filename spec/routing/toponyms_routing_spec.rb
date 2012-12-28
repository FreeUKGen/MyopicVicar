require "spec_helper"

describe ToponymsController do
  describe "routing" do

    it "routes to #index" do
      get("/toponyms").should route_to("toponyms#index")
    end

    it "routes to #new" do
      get("/toponyms/new").should route_to("toponyms#new")
    end

    it "routes to #show" do
      get("/toponyms/1").should route_to("toponyms#show", :id => "1")
    end

    it "routes to #edit" do
      get("/toponyms/1/edit").should route_to("toponyms#edit", :id => "1")
    end

    it "routes to #create" do
      post("/toponyms").should route_to("toponyms#create")
    end

    it "routes to #update" do
      put("/toponyms/1").should route_to("toponyms#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/toponyms/1").should route_to("toponyms#destroy", :id => "1")
    end

  end
end
