require 'json'

module SidekiqUniqueJobs
  module Normalizer
    def self.jsonify(args)
      JSON.parse(args.to_json)
    end
  end
end
