RSpec.describe 'bb.invariant', type: :bash do
  let(:import_path) { BishBashSupport.module_path('bb/import.sh') }
  let(:module_path) { BishBashSupport.module_path('bb/invariant.sh') }

  let(:valid) {
    RSpec::Bash::Script.new <<-EOF
      source "#{import_path}"

      bb.import.add_path "#{BishBashSupport.modules_path}"

      bb.import "bb/invariant.sh"

      bb.invariant true "nope!"
    EOF
  }

  let(:invalid) {
    RSpec::Bash::Script.new <<-EOF
      source "#{import_path}"

      bb.import.add_path "#{BishBashSupport.modules_path}"

      bb.import "bb/invariant.sh"

      bb.invariant false "nope!"
    EOF
  }

  it 'returns false if the predicate did not hold' do
    expect(run_script(invalid)).to be false
  end

  it 'prints an error message to STDERR' do
    run_script invalid

    expect(invalid.stderr).to include('nope!')
  end

  it 'returns true if the predicate did hold' do
    expect(run_script(valid)).to be true
  end
end