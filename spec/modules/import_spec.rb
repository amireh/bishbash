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

  context "with a package from github" do
    let(:home) { tmp_path('bishbash') }
    let(:mod_id) { "bb/tty.sh" }
    let(:mod_message) { 'hello from tty!' }
    let(:mod_contents) { "echo '#{mod_message}'" }
    let(:mod_url) { 'https://raw.githubusercontent.com/amireh/bishbash/43465dc4029194d6b8571de1d00a0a5564a736f5/modules/bb/tty.sh'}
    let(:mod_filepath) { "#{home}/modules/97c9bb2eff110552455db26b8a0cb56e40d7f4f2.sh" }

    before(:each) do
      allow(subject).to receive(:curl).and_return 1
    end

    subject {
      a_script <<-EOF
        export BISHBASH_HOME="#{home}"

        source "#{module_path}"

        import.add_package 'bb' 'github:amireh/bishbash#43465dc4029194d6b8571de1d00a0a5564a736f5/modules'
        import.checksum shasum

        $@
      EOF
    }

    it 'rejects modules that do not identify as part of such packages' do
      expect(subject).to receive(:curl).exactly(0)

      expect(run_script(subject, ["import", "cc/yyy.sh"])).to eq false
    end

    it 'attempts to fetch them using curl' do
      curl_args = nil

      expect(subject).to receive(:curl).once.and_yield { |args|
        curl_args = args

        <<-EOF
          return 1
        EOF
      }

      expect(run_script(subject, ["import", mod_id])).to eq false

      expect(curl_args).to include(mod_url)
    end

    it 'reports curl failures' do
      expect(subject).to receive(:curl).once.and_yield { |*|
        <<-EOF
          echo 'cURL: 404 Not Found' 1>&2
          return 1
        EOF
      }

      expect(run_script(subject, ["import", mod_id])).to eq false
      expect(subject.stderr).to include("cURL: 404 Not Found\n")
    end

    it 'stores them with their URL checkums for a name' do
      expect(subject).to receive(:curl).once.and_yield { |*|
        <<-EOF
          echo "#{mod_contents}"
          return 0
        EOF
      }

      expect {
        run_script(subject, ["import", mod_id])
      }.to change {
        File.exist?(mod_filepath)
      }.from(false).to(true)

      expect(File.read(mod_filepath)).to eq "#{mod_contents}\n"
    end

    it 'logs downloaded files in the manifest' do
      expect(subject).to receive(:curl).once.and_yield { |*|
        <<-EOF
          echo "#{mod_contents}"
          return 0
        EOF
      }

      run_script(subject, ["import", mod_id])

      manifest = File.read("#{home}/modules/manifest.txt")

      expect(manifest).to include(
        "\"#{mod_id}\" (#{mod_url}) => (#{mod_filepath})\n"
      )
    end

    it 'loads them from disk if it finds them' do
      File.write(mod_filepath, mod_contents)

      expect(subject).to receive(:curl).exactly(0)

      expect(run_script(subject, ["import", mod_id])).to eq(true)
      expect(subject.stdout).to include(mod_message)
    end

    it 'complains if it cannot find a program to checksum with' do
      subject = a_script <<-EOF
        export BISHBASH_HOME="#{home}"

        source "#{module_path}"

        import.add_package 'bb' 'github:amireh/bishbash#43465dc4029194d6b8571de1d00a0a5564a736f5'

        $@
      EOF

      expect(subject).to receive(:curl).never
      expect(subject).to (
        receive(:which)
          .with_args('sha256sum').once.and_return(1)
          .with_args('sha1sum').once.and_return(1)
          .with_args('shasum').once.and_return(1)
          .with_args('md5sum').once.and_return(1)
      )

      expect(run_script(subject, ["import", mod_id])).to eq(false)
      expect(subject.stderr).to include('import: unable to calculate digest')
    end
  end
end