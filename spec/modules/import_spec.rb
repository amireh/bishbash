RSpec.describe 'import', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/import.sh') }

  describe '.relpath' do
    it 'does its thing' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        import "#{BishBashSupport.fixture_path("relpath_import.sh")}"
      EOF

      run_script subject, []

      expect(subject.stdout.lines).to eq([
        "#{BishBashSupport.fixture_path('../support/array_spec.rb')}\n",
        "#{BishBashSupport.fixture_path('../')}\n",
        "#{BishBashSupport.fixture_path('../../')}\n",
        "#{BishBashSupport.fixture_path('~/foo')}\n",
        "/tmp/foo\n",
      ])
    end
  end

  describe '.import' do
    subject {
      RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        import "#{BishBashSupport.fixture_path("a.sh")}"
        import "#{BishBashSupport.fixture_path("a.sh")}"

        import "#{BishBashSupport.fixture_path("b.sh")}"
      EOF
    }

    it 'sources the script only once' do
      expect(subject).to (
        receive(:source)
          .thrice
          .with_args(module_path)
          .with_args("#{BishBashSupport.fixture_path("./a.sh")}")
          .with_args("#{BishBashSupport.fixture_path("./b.sh")}")
          .and_call_original
      )

      run_script subject

      expect(subject.stdout).to eq([ "a included\n", "b included\n"].join(''))
    end

    it 'returns false if the script could not be found' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        import "non-existent-file.sh"
      EOF

      expect(subject).to (
        receive(:source)
          .once
          .and_call_original
      )

      run_script subject

      expect(subject.exit_code).to eq(1)
      expect(subject.stderr).to include('import: cannot find module "non-existent-file.sh"')

    end

    it 'returns false if the script could not be sourced' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        import "#{BishBashSupport.fixture_path("fails.sh")}"
      EOF

      expect(subject).to (
        receive(:source)
          .twice
          .with_args(module_path)
          .with_args(BishBashSupport.fixture_path("fails.sh"))
          .and_call_original
      )

      run_script subject

      expect(subject.exit_code).to eq(1)
    end

    it 'returns true if the script was already loaded' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        import "#{BishBashSupport.fixture_path("a.sh")}"
        import "#{BishBashSupport.fixture_path("a.sh")}"
      EOF

      run_script subject

      expect(subject.exit_code).to eq(0)
    end
  end

  describe '.import with package modules' do
    subject {
      RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        import.add_package 'bb' '#{BishBashSupport.modules_path}'
        import "bb/at_exit.sh"
      EOF
    }

    it 'sources the script only once' do
      expect(subject).to (
        receive(:source)
          .twice
          .with_args(module_path)
          .with_args(BishBashSupport.module_path("bb/at_exit.sh"))
          .and_yield(subshell: false) do |x|
            if x == module_path
              "builtin source '#{x}'"
            else
              "return 0"
            end
          end
      )

      run_script subject, []

      expect(subject.exit_code).to eq(0)
    end
  end
end