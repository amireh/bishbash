RSpec.describe 'bb.platform', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/platform.sh') }

  describe '.is_function_available' do
    it 'returns true if the function is usable in the current shell' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        bb.platform.is_function_available "__foobarbaz__"
      EOF

      expect(run_script(subject)).to be false

      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        function __foobarbaz__() {
          return 0
        }

        bb.platform.is_function_available "__foobarbaz__"
      EOF

      expect(run_script(subject)).to be true
    end
  end

  describe '.is_command_available' do
    it 'delegates to "which"' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        bb.platform.is_command_available "__foobarbaz__"
      EOF

      expect(subject).to receive(:which).with_args("__foobarbaz__").and_return(1)
      expect(run_script(subject)).to be false
    end
  end

  describe '.source_profile' do
    subject {
      RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        bb.platform.source_profile
      EOF
    }

    it 'tries to source "~/.bash_profile" first' do
      expect(subject).to (
        test('-e')
          .with_args(File.expand_path("~/.bash_profile"))
          .and_return 0
      )

      expect(subject).to (
        receive(:source)
          .twice
          .with_args(module_path)
          .with_args(File.expand_path("~/.bash_profile"))
          .and_yield(subshell: false) { |x|
            x =~ /\.bash_profile/ ? "return 0" : "builtin source '#{x}'"
          }
      )

      expect(run_script(subject)).to be true
    end

    it 'tries to source "~/.profile" if bash-specific profile is not found' do
      expect(subject).to (
        test('-e')
          .with_args(File.expand_path("~/.bash_profile"))
          .with_args(File.expand_path("~/.profile"))
          .and_yield { |x| x =~ /\.bash_profile/ ? "return 1" : "return 0" }
      )

      expect(subject).to (
        receive(:source)
          .twice
          .with_args(module_path)
          .with_args(File.expand_path("~/.profile"))
          .and_yield(subshell: false) { |x|
            x =~ /\.profile/ ? "return 0" : "builtin source '#{x}'"
          }
      )

      expect(run_script(subject)).to be true
    end

    it 'tries to source "/etc/profile" if no user-specific profile is not found' do
      expect(subject).to (
        test('-e')
          .with_args(File.expand_path("~/.bash_profile"))
          .with_args(File.expand_path("~/.profile"))
          .with_args(File.expand_path("/etc/profile"))
          .and_yield { |x| x == '/etc/profile' ? 'return 0' : 'return 1' }
      )

      expect(subject).to (
        receive(:source)
          .twice
          .with_args(module_path)
          .with_args(File.expand_path("/etc/profile"))
          .and_yield(subshell: false) { |x|
            x == '/etc/profile' ? "return 0" : "builtin source '#{x}'"
          }
      )

      expect(run_script(subject)).to be true
    end

    it 'returns false if no profile was found' do
      expect(subject).to (
        test('-e')
          .thrice
          .with_args(File.expand_path("~/.bash_profile"))
          .with_args(File.expand_path("~/.profile"))
          .with_args(File.expand_path("/etc/profile"))
          .and_return 1
      )

      expect(subject).to (
        receive(:source)
          .once
          .and_call_original
      )

      expect(run_script(subject)).to be false
    end
  end
end
