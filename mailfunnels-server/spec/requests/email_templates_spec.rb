require 'rails_helper'

RSpec.describe "EmailTemplates", type: :request do
  describe "GET /email_templates" do
    it "works! (now write some real specs)" do
      get email_templates_path
      expect(response).to have_http_status(200)
    end
  end
end
