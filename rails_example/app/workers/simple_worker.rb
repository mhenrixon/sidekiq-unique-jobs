class SimpleWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  queue: :default,
                  unique_args: (lambda do |args|
                    puts "args = #{args}"
                    puts "args.first = #{args.first}"
                    [args]
                  end)

  def perform(some_args)
    puts "some_arg = #{some_args}"
    sleep 60
  end
end
