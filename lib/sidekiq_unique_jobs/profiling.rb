require "timeasure"

SidekiqUniqueJobs::ClientMiddleware.class_eval do
  include Timeasure
  tracked_instance_methods :call
end

SidekiqUniqueJobs::ServerMiddleware.class_eval do
  include Timeasure
  tracked_instance_methods :call
end
