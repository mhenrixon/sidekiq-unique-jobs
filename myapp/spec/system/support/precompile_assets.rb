# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    examples = RSpec.world.filtered_examples.values.flatten
    has_no_system_tests = examples.none? { |example| example.metadata[:type] == :system }

    if has_no_system_tests
      $stdout.puts "\n🚀️️  No system test selected. Skip assets compilation.\n"
      next
    end

    $stdout.puts "\n🐢  Precompiling assets.\n"
    original_stdout = $stdout.clone
    start = Time.current
    begin
      $stdout.reopen(File.new("/dev/null", "w"))
      system("yarn build:css")
    ensure
      $stdout.reopen(original_stdout)
      $stdout.puts "Finished in #{(Time.current - start).round(2)} seconds"
    end
  end

  config.after(:suite) do
    # $stdout.puts "\n🐇  Clobbering assets.\n"
    # system("bin/rails assets:clobber && touch app/assets/stylesheets/application.tailwind.css")
  end
end
