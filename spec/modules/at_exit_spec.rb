RSpec.describe 'bb.at_exit', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/at_exit.sh') }

  subject {
    RSpec::Bash::Script.new <<-EOF
      source "#{module_path}"

      bb.at_exit "echo 'done!'"
    EOF
  }

  it 'runs the command upon exit' do
    run_script subject
    expect(subject.stdout).to eq("done!\n")
  end
end