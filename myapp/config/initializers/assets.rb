# frozen_string_literal: true

# Propshaft automatically serves assets from app/assets/builds
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "builds")
