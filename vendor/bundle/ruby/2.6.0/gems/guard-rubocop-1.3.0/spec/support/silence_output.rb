RSpec.shared_context 'silence output', :silence_output do
  null_object = BasicObject.new

  class << null_object
    # #respond_to_missing? does not work.
    def respond_to?(*)
      true
    end

    def method_missing(*)
    end
  end

  before do
    @original_stdout = $stdout
    @original_stderr = $stderr
    $stdout = null_object
    $stderr = null_object
  end

  after do
    $stdout = @original_stdout
    $stderr = @original_stderr
  end
end
