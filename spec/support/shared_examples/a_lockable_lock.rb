# frozen_string_literal: true

RSpec.shared_examples 'a lock implementation' do
  it 'can be locked' do
    expect(process_one.lock).to eq(jid_one)
  end

  context 'when process one has locked the job' do
    before { process_one.lock }

    it 'has locked process_one' do
      expect(process_one.locked?).to eq(true)
    end

    it 'prevents process_two from locking' do
      expect(process_two.lock).to eq(nil)
    end

    it 'prevents process_two from executing' do
      expect(process_two.execute {}).to eq(nil)
    end
  end
end

RSpec.shared_examples 'an executing lock implementation' do
  context 'when job has not been locked' do
    it 'does not execute' do
      unset = true
      process_one.execute { unset = false }
      expect(unset).to eq(true)
    end
  end

  context 'when process_one executes the job' do
    before { process_one.lock }

    it 'keeps being locked while executing' do
      process_one.execute do
        expect(process_one.locked?).to eq(true)
      end
    end

    it 'keeps being locked when an error is raised' do
      expect { process_one.execute { raise 'Hell' } }
        .to raise_error('Hell')

      expect(process_one.locked?).to eq(true)
    end

    it 'prevents process_two from locking' do
      process_one.execute do
        expect(process_two.lock).to eq(nil)
        expect(process_two.locked?).to eq(false)
      end
    end

    it 'prevents process_two from executing' do
      process_one.execute do
        unset = true
        process_two.execute { unset = false }
        expect(unset).to eq(true)
      end
    end
  end
end
