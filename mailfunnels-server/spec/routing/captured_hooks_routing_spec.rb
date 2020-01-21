require "rails_helper"

RSpec.describe CapturedHooksController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/captured_hooks").to route_to("captured_hooks#index")
    end


    it "routes to #show" do
      expect(:get => "/captured_hooks/1").to route_to("captured_hooks#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/captured_hooks").to route_to("captured_hooks#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/captured_hooks/1").to route_to("captured_hooks#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/captured_hooks/1").to route_to("captured_hooks#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/captured_hooks/1").to route_to("captured_hooks#destroy", :id => "1")
    end

  end
end
