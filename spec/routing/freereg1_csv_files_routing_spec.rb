require "spec_helper"

describe Freereg1CsvFilesController do
  describe "routing" do

    it "routes to #index" do
      get("/freereg1_csv_files").should route_to("freereg1_csv_files#index")
    end

    it "routes to #new" do
      get("/freereg1_csv_files/new").should route_to("freereg1_csv_files#new")
    end

    it "routes to #show" do
      get("/freereg1_csv_files/1").should route_to("freereg1_csv_files#show", :id => "1")
    end

    it "routes to #edit" do
      get("/freereg1_csv_files/1/edit").should route_to("freereg1_csv_files#edit", :id => "1")
    end

    it "routes to #create" do
      post("/freereg1_csv_files").should route_to("freereg1_csv_files#create")
    end

    it "routes to #update" do
      put("/freereg1_csv_files/1").should route_to("freereg1_csv_files#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/freereg1_csv_files/1").should route_to("freereg1_csv_files#destroy", :id => "1")
    end

  end
end
