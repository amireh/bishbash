RSpec.describe 'tasks', type: :bash do
  let(:module_path) { BishBashSupport.module_path('bb/tasks.sh') }

  it 'defines a task' do
    subject = a_script_with_import <<-EOF
      import "#{module_path}"

      tasks.define "foo"
    EOF

    expect(run_script(subject)).to be true
  end

  it 'sources a task' do
    create_file 'tasks/foo.sh', <<-EOF
      echo "task sourced"
    EOF

    subject = a_script_with_import <<-EOF
      import "#{module_path}"

      tasks.define "foo"
      tasks.run_all "#{tmp_path('tasks')}" "up"
    EOF

    expect(run_script(subject)).to be true
    expect(subject.stdout).to include('task sourced')
  end

  it 'reports failures in sourcing a task' do
    create_file 'tasks/foo.sh', <<-EOF
      exit 1
    EOF

    subject = a_script_with_import <<-EOF
      import "#{module_path}"

      tasks.define "foo"
      tasks.run_all "#{tmp_path('tasks')}" "up"
    EOF

    expect(run_script(subject)).to be false
    expect(subject.stderr).to include('[foo] FAILED!')
  end

  it 'runs the requested hook of a task' do
    create_file 'tasks/foo.sh', <<-EOF
      function up() {
        echo "task up"
      }
    EOF

    subject = a_script_with_import <<-EOF
      import "#{module_path}"

      tasks.define "foo"
      tasks.run_all "#{tmp_path('tasks')}" "up"
    EOF

    expect(run_script(subject)).to be true
    expect(subject.stdout).to include('task up')
  end

  it 'returns true if the task does not implement the hook' do
    create_file 'tasks/foo.sh', <<-EOF
      # nothing here
    EOF

    subject = a_script_with_import <<-EOF
      import "#{module_path}"

      tasks.define "foo"
      tasks.run_all "#{tmp_path('tasks')}" "up"
    EOF

    expect(run_script(subject)).to be true
  end

  it 'reports failures from a task hook' do
    create_file 'tasks/foo.sh', <<-EOF
      function up() {
        return 3
      }
    EOF

    subject = a_script_with_import <<-EOF
      import "#{module_path}"

      tasks.define "foo"
      tasks.run_all "#{tmp_path('tasks')}" "up"
    EOF

    expect(run_script(subject)).to be false
    expect(subject.stderr).to include('[foo] FAILED! (exit code 3)')
  end

  describe 'filtering' do
    subject do
      create_file 'tasks/a.sh', 'echo "a included"'
      create_file 'tasks/b.sh', 'echo "b included"'
      create_file 'tasks/c.sh', 'echo "c included"'
      create_file 'tasks/d.sh', 'echo "d included"'

      a_script_with_import <<-EOF
        import "#{module_path}"

        tasks.define "a"
        tasks.define "b"
        tasks.define "c"
        tasks.define "d"

        tasks.read_wants "$@"
        tasks.run_all "#{tmp_path('tasks')}" "up"
      EOF
    end

    it 'selects a task using -o' do
      expect(run_script(subject, ["-o", "a", "-o", "d"])).to be true

      expect(subject.stdout).to include('a included')
      expect(subject.stdout).not_to include('b included')
      expect(subject.stdout).not_to include('c included')
      expect(subject.stdout).to include('d included')
    end

    it 'skips a task using -s' do
      expect(run_script(subject, ["-s", "a", "-s", "d"])).to be true

      expect(subject.stdout).not_to include('a included')
      expect(subject.stdout).to include('b included')
      expect(subject.stdout).to include('c included')
      expect(subject.stdout).not_to include('d included')
    end

    it 'complains about unknown tasks' do
      expect(run_script(subject, ["-s", "foo"])).to be false

      expect(subject.stderr).to include('Unrecognized task "foo"')
    end
  end

  describe 'help listing' do
    subject do
      create_file 'tasks/a.sh', <<-EOF
        tasks.describe "A does this"
      EOF

      create_file 'tasks/b.sh', <<-EOF
        tasks.describe "B does that"
        tasks.option "B_OPT" "description of B option"
      EOF

      a_script_with_import <<-EOF
        import "#{module_path}"

        tasks.define "a"
        tasks.define "b"

        tasks.print_help "#{tmp_path('tasks')}"
      EOF
    end

    before(:each) do
      expect(run_script(subject)).to eq true
    end

    it 'describes a task' do
      expect(subject.stdout).to include('A does this')
      expect(subject.stdout).to include('B does that')
    end

    it 'describes env options' do
      expect(subject.stdout).to include('B_OPT')
      expect(subject.stdout).to include('description of B option')
    end
  end
end
