require "rails_helper"

RSpec.describe FunnelsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/funnels").to route_to("funnels#index")
    end


    it "routes to #show" do
      expect(:get => "/funnels/1").to route_to("funnels#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/funnels").to route_to("funnels#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/funnels/1").to route_to("funnels#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/funnels/1").to route_to("funnels#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/funnels/1").to route_to("funnels#destroy", :id => "1")
    end

  end
end
