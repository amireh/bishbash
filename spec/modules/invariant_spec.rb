RSpec.describe 'invariant', type: :bash do
  let(:import_path) { BishBashSupport.module_path('bb/import.sh') }
  let(:module_path) { BishBashSupport.module_path('bb/invariant.sh') }
  let(:imports) {
    <<-EOF
      source "#{import_path}"
      import.add_path "#{BishBashSupport.modules_path}"
      import "bb/invariant.sh"
    EOF
  }

  let(:valid) {
    RSpec::Bash::Script.new <<-EOF
      #{imports}

      invariant $(true) "nope!"
    EOF
  }

  let(:invalid) {
    RSpec::Bash::Script.new <<-EOF
      #{imports}

      invariant $(false) "nope!"
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

  describe 'variants' do
    it 'using the "test" builtin' do
      expect(
        run_script(
          RSpec::Bash::Script.new <<-EOF
            #{imports}

            invariant $(test ! -z "") "nope!"
          EOF
        )
      ).to be false

      expect(
        run_script(
          RSpec::Bash::Script.new <<-EOF
            #{imports}

            invariant $(test -n "asdf") "nope!"
          EOF
        )
      ).to be true
    end

    it 'using the "[" builtin' do
      expect(
        run_script(
          RSpec::Bash::Script.new <<-EOF
            #{imports}

            invariant $([ ! -z "" ]) "nope!"
          EOF
        )
      ).to be false

      expect(
        run_script(
          RSpec::Bash::Script.new <<-EOF
            #{imports}

            invariant $([ -n "asdf" ]) "nope!"
          EOF
        )
      ).to be true
    end

    # doesn't really work, keeps propping up edge cases (e.g. if the test
    # operator is binary and the argument is empty, it gets lost through
    # the function calls causing the [[ keyword operator itself to break
    # since the expression is then malformed)
    it 'using the "[[" operator, it evaluates falseys' do
      samples = []
      samples.push RSpec::Bash::Script.new <<-EOF
        #{imports}

        invariant $([[ ! -z "" ]]) "nope!"
      EOF

      samples.push RSpec::Bash::Script.new <<-EOF
        #{imports}

        invariant $([[ ! -z "" ]]) "nope!"
      EOF

      samples.each do |subject|
        expect(run_script(subject)).to be false
        expect(subject.stderr).to include("nope!")
      end
    end

    it 'using the "[[" operator, it evaluates truthies' do
      samples = []
      samples.push RSpec::Bash::Script.new <<-EOF
        #{imports}

        invariant $([[ -n "foo" ]]) "nope!"
      EOF

      samples.push RSpec::Bash::Script.new <<-EOF
        #{imports}

        invariant $([[ ! -n "" ]]) "nope!"
      EOF

      samples.each do |subject|
        expect(run_script(subject, [], verbose: true)).to be true
        expect(subject.stderr).to be_empty
      end
    end
  end
end