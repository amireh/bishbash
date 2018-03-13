RSpec.describe 'import-with-symbols', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/import-with-symbols.sh') }

  it 'sources the correct script' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"
      import array.* : "#{BishBashSupport.module_path("bb/array.sh")}"
    EOF

    expect(subject).to (
      receive(:source)
        .twice
        .with_args(module_path)
        .with_args(BishBashSupport.module_path("bb/array.sh"))
        .and_call_original
    )

    run_script subject, []

    expect(subject.exit_code).to eq(0)
  end

  it 'exports public symbols and forwards arguments as expected' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      import array.* : "#{BishBashSupport.module_path("bb/array.sh")}"

      declare -f -F array.contains
      declare -f -F contains
      declare list=("one" "two" "three")

      array.is_empty "${list[@]}" && echo "bad"
      array.contains "${list[@]}" "one" && echo "good"
      array.contains "${list[@]}" "four" && echo "bad"
      $(array.last "${list[@]}") != "three" && echo "bad"

      exit 0
    EOF

    run_script subject, []

    expect(subject.exit_code).to eq(0)
    expect(subject.stdout).to include("array.contains\n")
    expect(subject.stdout).to match(/^contains\n/)
    expect(subject.stdout).to include("good\n")
    expect(subject.stdout).to_not include("bad\n")
  end

  it 'exports a single public symbols' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      import array.is_empty : "#{BishBashSupport.module_path("bb/array.sh")}"

      declare -f -F array.is_empty
    EOF

    run_script subject, []

    expect(subject.exit_code).to eq(0)
    expect(subject.stdout).to include("array.is_empty\n")
  end

  it 'does not export private symbols' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      import stacktrace.* : "#{BishBashSupport.module_path("bb/stacktrace.sh")}"

      declare -f -F stacktrace.print || exit 1
      declare -f -F stacktrace.__clean && exit 1

      exit 0
    EOF

    run_script subject, []

    expect(subject.exit_code).to eq 0
    expect(subject.stdout).to include("stacktrace.print\n")
    expect(subject.stdout).to_not include("stacktrace.__clean\n")
  end
end