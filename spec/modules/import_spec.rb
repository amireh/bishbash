RSpec.describe 'import', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/import.sh') }

  describe 'import.resolve' do
    path = BishBashSupport.tmp_path('resolve-spec/script.sh')
    root = File.expand_path('../../../', path)
    dir = File.dirname(path)

    samples = [
      {
        input: './',
        output: "#{root}/tmp/resolve-spec"
      },
      {
        input: '../',
        output: "#{root}/tmp"
      },
      {
        input: '../../',
        output: "#{root}"
      },
      {
        input: './foo',
        output: "#{root}/tmp/resolve-spec/foo"
      },
      {
        input: '../foo',
        output: "#{root}/tmp/foo"
      },
      {
        input: '../foo/a',
        output: "#{root}/tmp/foo/a"
      },
      {
        input: '~/foo',
        output: "#{root}/tmp/resolve-spec/~/foo"
      },
      {
        input: '/foo',
        output: '/foo'
      },
    ]

    samples.each do |input:, output:|
      before(:each) do
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      end

      after(:each) do
        Dir.glob("#{dir}/*").each do |f|
          File.unlink(f)
        end

        FileUtils.rmdir(dir)
      end

      it "works for '#{input}'" do
        subject = a_script <<-EOF
          source "#{module_path}"
          import.resolve "#{input}"
        EOF

        run_script subject, [], file: File.new(path, 'w')

        expect(subject.exit_code).to eq 0
        expect(subject.stdout).to eq "#{output}\n"
      end
    end
  end

  describe '.import' do
    subject {
      a_script <<-EOF
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
      subject = a_script <<-EOF
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
      subject = a_script <<-EOF
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
      subject = a_script <<-EOF
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
      a_script <<-EOF
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