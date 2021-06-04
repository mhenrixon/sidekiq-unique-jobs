# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Module Reflectable provides a method to notify subscribers
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module Reflectable
    def reflect(name, *args)
      SidekiqUniqueJobs.reflections.dispatch(name, *args)
      nil
    rescue UniqueJobsError => ex
      SidekiqUniqueJobs.logger.error(ex)
    end
  end
end
