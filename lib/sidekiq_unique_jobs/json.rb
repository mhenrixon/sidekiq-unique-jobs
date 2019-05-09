# frozen_string_literal: true

module SidekiqUniqueJobs
  # Handles loading and dumping of json
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module JSON
    module_function

    def load_json(string)
      ::JSON.parse(string)
    end

    def dump_json(object)
      ::JSON.generate(object)
    end
  end
end
