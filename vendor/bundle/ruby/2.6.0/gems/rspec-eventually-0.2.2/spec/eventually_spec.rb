module Rspec
  module Eventually
    describe Eventually do
      it 'eventually matches' do
        value = 0
        Thread.new do
          sleep 0.5
          value = 1
        end

        expect(Eventually.new(eq 1).matches?(-> { value })).to be true
      end

      it 'eventually_not matches' do
        value = 0
        Thread.new do
          sleep 0.5
          value = 1
        end

        expect(Eventually.new(eq 0).not.matches?(-> { value })).to be true
      end

      it 'eventually fails' do
        expect(Eventually.new(eq 1).matches?(-> { 0 })).to be false
      end

      it 'eventually_not fails' do
        expect(Eventually.new(eq 1).not.matches?(-> { 1 })).to be false
      end

      it 'has a configurable default timeout' do
        begin
          ::Rspec::Eventually.timeout = 1
          expect(::Rspec::Eventually.timeout).to eq 1

          before = Time.now
          Eventually.new(eq 1).matches? -> { 0 }
          took = Time.now - before
          expect(took).to be_within(0.5).of 1
        ensure
          ::Rspec::Eventually.timeout = 5
        end
      end

      it 'can have a specific timeout' do
        before = Time.now
        Eventually.new(eq 1).within(0.5).matches? -> { 0 }
        took = Time.now - before
        expect(took).to be_within(0.1).of 0.5
      end

      it 'has a configurable default pause' do
        begin
          ::Rspec::Eventually.pause = 0.5
          expect(::Rspec::Eventually.pause).to eq 0.5

          matcher = Eventually.new(eq 1)
          matcher.matches? -> { 0 }

          expect(matcher.instance_variable_get('@tries')).to eq 9
        ensure
          ::Rspec::Eventually.pause = 0.1
        end
      end

      it 'can have a specific pause' do
        matcher = Eventually.new(eq 1)
        matcher.pause_for(1.5).matches? -> { 0 }

        expect(matcher.instance_variable_get('@tries')).to eq 3
      end

      it 'can have a specific pause and timeout' do
        matcher = Eventually.new(eq 1)
        matcher.pause_for(1).within(3).matches? -> { 0 }

        expect(matcher.instance_variable_get('@tries')).to eq 2
      end

      it 'it will not pause when evaluation is true' do
        before = Time.now
        matcher = Eventually.new(eq 1)
        matcher.pause_for(1).matches? -> { 1 }
        took = Time.now - before

        expect(matcher.instance_variable_get('@tries')).to eq 0
        expect(took).to be < 1
      end

      it 'raises errors by default' do
        block = lambda do
          Eventually.new(eq 1).matches? -> { raise 'I am throwing an error' }
        end

        expect { block.call }.to raise_error(/I am throwing an error/)
      end

      it 'can suppress errors' do
        first = false
        block = lambda do
          one_eventually = lambda do
            if first
              first = false
              raise 'I am throwing an error'
            end
            1
          end

          Eventually.new(eq 1).by_suppressing_errors.matches? one_eventually
        end

        expect { block.call }.to_not raise_error
        expect(block.call).to be true
      end

      it 'produces a coherent failure message' do
        (matcher = Eventually.new(eq 1).within(0.5)).matches? -> { 0 }
        message = matcher.failure_message
        expect(message).to match(/After [0-9]+ tries, the last failure message was/)
        expect(message).to match(/expected: 1/)
        expect(message).to match(/got: 0/)
      end

      it 'raises an error when negated' do
        expect { Eventually.new(eq 1).does_not_match? }.to raise_error(/Use eventually_not/)
      end

      it 'raises an error when timeout occurs before the first evaluation' do
        block = lambda do
          Eventually.new(eq 1).within(0.5).matches? -> { sleep 5 }
        end

        expect { block.call }.to raise_error(/Timeout before first evaluation/)
      end

      it 'raises an error when timeout occurs before the first evaluation due to long pause' do
        block = lambda do
          Eventually.new(eq 1).pause_for(1).within(0.5).matches? -> { sleep 5 }
        end

        expect { block.call }.to raise_error(/Timeout before first evaluation/)
      end

      it 'supports custom error messages' do
        (matcher = Eventually.new(eq(1), '0 is not within 0.5 of 1').within(0.5)).matches? -> { 0 }
        message = matcher.failure_message
        expect(message).to match(/After [0-9]+ tries, the last failure message was/)
        expect(message).to match(/0 is not within 0.5 of 1/)
      end
    end
  end
end
