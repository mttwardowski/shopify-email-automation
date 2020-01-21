require 'rails_helper'

RSpec.describe "CapturedHooks", type: :request do
  describe "GET /captured_hooks" do
    it "works! (now write some real specs)" do
      get captured_hooks_path
      expect(response).to have_http_status(200)
    end
  end
end
