# frozen_string_literal: true

# Add builds directory so Propshaft can serve CSS compiled by Tailwind CLI
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "builds")
