RSpec.describe 'array', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/array.sh') }

  describe 'array.last' do
    subject {
      RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        array.last "$@"
      EOF
    }

    it 'retrieves the last item in a list' do
      run_script subject, %w[One Two]

      expect(subject.stdout).to eq("Two\n")
    end

    it 'works with an empty list' do
      run_script subject, %w[]

      expect(subject.stdout).to be_empty
    end
  end

  describe 'array.tail' do
    subject {
      RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        array.tail "$@"
      EOF
    }

    it 'removes the last item in a list' do
      run_script subject, %w[One Two Three]

      expect(subject.stdout).to eq("One Two\n")
    end

    it 'works with an empty list' do
      run_script subject, %w[]

      expect(subject.stdout).to be_empty
    end
  end

  describe 'array.contains' do
    subject {
      RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        array.contains "$@"
      EOF
    }

    it 'returns 0 if the item exists in a list' do
      run_script subject, ["One Two Three", "One"]

      expect(subject.exit_code).to eq(0)
    end

    it 'returns 1 if the item does not exist in a list' do
      run_script subject, ["One Two Three", "Four"]

      expect(subject.exit_code).to eq(1)
    end

    it 'returns 1 if the list is empty anyway' do
      run_script subject, %w[]

      expect(subject.exit_code).to eq(1)
    end

    it 'returns 1 if the item is empty anyway' do
      run_script subject, ['One Two', '']

      expect(subject.exit_code).to eq(1)
    end
  end
end