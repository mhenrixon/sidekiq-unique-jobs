# frozen_string_literal: true

require "json"

module SidekiqUniqueJobs
  # Normalizes hashes by dumping them to json and loading them from json
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Normalizer
    # Changes hash to a json compatible hash
    # @param [Hash] args
    # @return [Hash] a json compatible hash
    def self.jsonify(args)
      Sidekiq.load_json(Sidekiq.dump_json(args))
    end
  end
end
