require "spec_helper"

describe Freereg1CsvEntriesController do
  describe "routing" do

    it "routes to #index" do
      get("/freereg1_csv_entries").should route_to("freereg1_csv_entries#index")
    end

    it "routes to #new" do
      get("/freereg1_csv_entries/new").should route_to("freereg1_csv_entries#new")
    end

    it "routes to #show" do
      get("/freereg1_csv_entries/1").should route_to("freereg1_csv_entries#show", :id => "1")
    end

    it "routes to #edit" do
      get("/freereg1_csv_entries/1/edit").should route_to("freereg1_csv_entries#edit", :id => "1")
    end

    it "routes to #create" do
      post("/freereg1_csv_entries").should route_to("freereg1_csv_entries#create")
    end

    it "routes to #update" do
      put("/freereg1_csv_entries/1").should route_to("freereg1_csv_entries#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/freereg1_csv_entries/1").should route_to("freereg1_csv_entries#destroy", :id => "1")
    end

  end
end
