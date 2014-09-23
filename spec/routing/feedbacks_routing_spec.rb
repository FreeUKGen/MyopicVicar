require "spec_helper"

describe FeedbacksController do
  describe "routing" do

    it "routes to #index" do
      get("/feedbacks").should route_to("feedbacks#index")
    end

    it "routes to #new" do
      get("/feedbacks/new").should route_to("feedbacks#new")
    end

    it "routes to #show" do
      get("/feedbacks/1").should route_to("feedbacks#show", :id => "1")
    end

    it "routes to #edit" do
      get("/feedbacks/1/edit").should route_to("feedbacks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/feedbacks").should route_to("feedbacks#create")
    end

    it "routes to #update" do
      put("/feedbacks/1").should route_to("feedbacks#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/feedbacks/1").should route_to("feedbacks#destroy", :id => "1")
    end

  end
end
