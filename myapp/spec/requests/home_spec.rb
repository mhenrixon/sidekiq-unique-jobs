# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locks Dashboard", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"

      expect(response).to have_http_status(:success)
    end

    it "renders the lock testing dashboard" do
      get "/"

      expect(response.body).to include("Lock Testing Dashboard")
    end
  end

  describe "GET /locks/:id" do
    it "returns http success for a known job" do
      get "/locks/UntilExecutedJob"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("UntilExecutedJob")
    end

    it "returns not found for unknown job" do
      get "/locks/UnknownJob"

      expect(response).to have_http_status(:not_found)
    end
  end
end
