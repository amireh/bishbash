RSpec.describe 'bb.import', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/import.sh') }

  subject {
    RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      bb.import "#{BishBashSupport.fixture_path("a.sh")}"
      bb.import "#{BishBashSupport.fixture_path("a.sh")}"

      bb.import "#{BishBashSupport.fixture_path("b.sh")}"
    EOF
  }

  describe '.relpath' do
    it 'does its thing' do
      subject = RSpec::Bash::Script.new <<-EOF
        source "#{module_path}"

        bb.import "#{BishBashSupport.fixture_path("relpath_import.sh")}"
      EOF

      run_script subject, [], verbose: true

      expect(subject.stdout).to eq("#{BishBashSupport.fixture_path('../support/array_spec.rb')}\n")
    end
  end

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

      bb.import "non-existent-file.sh"
    EOF

    expect(subject).to (
      receive(:source)
        .once
        .and_call_original
    )

    run_script subject

    expect(subject.exit_code).to eq(1)
    expect(subject.stderr).to include('Unable to import "non-existent-file.sh": file not found')

  end

  it 'returns false if the script could not be sourced' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      bb.import "#{BishBashSupport.fixture_path("fails.sh")}"
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

      bb.import "#{BishBashSupport.fixture_path("a.sh")}"
      bb.import "#{BishBashSupport.fixture_path("a.sh")}"
    EOF

    run_script subject

    expect(subject.exit_code).to eq(0)
  end
end