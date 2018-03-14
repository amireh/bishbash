RSpec.describe 'nprintf', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/nprintf.sh') }

  it 'trims leading indentation' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      nprintf """
        Hello World! \
        This should be on the same line.

        This should be on a different line.
      """
    EOF

    expect(run_script(subject)).to be true
    expect(subject.stdout).to eq(
      "\nHello World! This should be on the same line.\n\nThis should be on a different line.\n"
    )
  end

  it 'lets me use printf-style formatting' do
    subject = RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      nprintf """
        Hello %s!
      """ "World"
    EOF

    expect(run_script(subject)).to be true
    expect(subject.stdout).to eq("\nHello World!\n")
  end
end
