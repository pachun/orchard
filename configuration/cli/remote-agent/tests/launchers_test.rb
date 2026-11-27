require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"

class LaunchersTest < Minitest::Test
  FEATURE = File.expand_path("..", __dir__)

  def setup
    @directory = Dir.mktmpdir("remote-agent-test-")
    @bin = File.join(@directory, "bin")
    @events = File.join(@directory, "events")
    @remote_home = File.join(@directory, "remote home")
    FileUtils.mkdir_p([@bin, @remote_home])
    @environment = {
      "PATH" => "#{@bin}:#{ENV.fetch('PATH')}",
      "AGENT_TEST_EVENTS" => @events,
      "AGENT_TEST_HOME" => @remote_home
    }
    executable("ssh", <<~'RUBY')
      require "json"
      File.open(ENV.fetch("AGENT_TEST_EVENTS"), "a") { |file| file.puts(JSON.generate(["ssh", *ARGV])) }
      exit 255 if ENV["AGENT_TEST_SSH_FAIL"]
      if ARGV.last.include?("codex app-server daemon start")
        puts ENV.fetch("AGENT_TEST_HOME")
        puts File.join(ENV.fetch("AGENT_TEST_HOME"), ".codex/app-server-control/app-server-control.sock")
      elsif ARGV.include?("-fNM") || ARGV.include?("-O")
        exit 0
      else
        exec({"HOME" => ENV.fetch("AGENT_TEST_HOME")}, "sh", "-c", ARGV.last)
      end
    RUBY
    executable("codex", <<~'RUBY')
      require "json"
      File.open(ENV.fetch("AGENT_TEST_EVENTS"), "a") { |file| file.puts(JSON.generate(["codex", *ARGV])) }
      socket = ARGV.fetch(ARGV.index("--remote") + 1).delete_prefix("unix://")
      abort "Tunnel directory is not private" unless File.stat(File.dirname(socket)).mode & 0777 == 0700
      puts "Connected"
      exit Integer(ENV.fetch("AGENT_TEST_CODEX_EXIT", "0"))
    RUBY
    executable("claude", <<~'RUBY')
      require "json"
      File.open(ENV.fetch("AGENT_TEST_EVENTS"), "a") { |file| file.puts(JSON.generate(["claude", Dir.pwd, *ARGV])) }
      puts "Claude ready"
    RUBY
    executable("tmux", <<~'RUBY')
      require "json"
      File.open(ENV.fetch("AGENT_TEST_EVENTS"), "a") { |file| file.puts(JSON.generate(["tmux", *ARGV])) }
      if ARGV.first == "new-session"
        exec "sh", "-c", ARGV.last
      elsif ARGV.first == "list-sessions"
        puts "claude-existing  1 window(s)  0 attached"
      end
    RUBY
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def executable(name, source)
    path = File.join(@bin, name)
    File.write(path, "#!/usr/bin/env ruby\n#{source}")
    File.chmod(0755, path)
  end

  def launch(agent, *arguments)
    Open3.capture3(@environment, File.join(FEATURE, "bin", "#{agent}-on"), *arguments)
  end

  def events
    File.exist?(@events) ? File.readlines(@events).map { |line| JSON.parse(line) } : []
  end

  def test_new_codex_session_uses_selected_device_home_and_private_tunnel
    output, error, status = launch("codex", "xps")
    assert status.success?, error
    assert_includes output, "Connected"
    invocation = events.find { |event| event.first == "codex" }
    assert_equal ["-C", @remote_home], invocation.last(2)
    forwarding = events.find { |event| event.include?("-fNM") }
    assert_equal "xps", forwarding.last
    socket = invocation[2].delete_prefix("unix://")
    refute File.exist?(File.dirname(socket)), "Temporary tunnel directory must be removed"
    assert_equal ["-O", "exit", "xps"], events.last.last(3)
  end

  def test_codex_resume_preserves_id_and_expands_remote_tilde_directory
    _, error, status = launch("codex", "other-user@framework", "resume", "conversation-id", "-C", "~/code/otto")
    assert status.success?, error
    invocation = events.find { |event| event.first == "codex" }
    assert_equal ["resume", "conversation-id", "-C", File.join(@remote_home, "code/otto")], invocation.drop(3)
  end

  def test_codex_failure_closes_tunnel_and_preserves_exit_status
    @environment["AGENT_TEST_CODEX_EXIT"] = "7"
    _, _, status = launch("codex", "framework")
    assert_equal 7, status.exitstatus
    assert_equal ["-O", "exit", "framework"], events.last.last(3)
  end

  def test_ssh_failure_does_not_start_local_agent
    @environment["AGENT_TEST_SSH_FAIL"] = "1"
    _, error, status = launch("codex", "framework")
    refute status.success?
    assert_includes error, "Check SSH access"
    refute events.any? { |event| event.first == "codex" }
  end

  def test_claude_prompt_and_directory_are_literal_and_session_can_be_reattached
    folder = "project 'with spaces'"
    FileUtils.mkdir_p(File.join(@remote_home, folder))
    marker = File.join(@directory, "unexpected-command")
    prompt = "Check `touch #{marker}` and $(touch #{marker})\nDon't execute these."
    output, error, status = launch("claude", "framework", "--cd", "~/#{folder}", prompt)
    assert status.success?, error
    assert_includes output, "Claude ready"
    assert_equal ["claude", File.join(@remote_home, folder), prompt], events.find { |event| event.first == "claude" }
    refute File.exist?(marker)
    creation = events.find { |event| event[0..1] == ["tmux", "new-session"] }
    assert_includes creation, "-d"
    session = creation.fetch(creation.index("-s") + 1)
    assert_includes error, "claude-on framework --attach #{session}"
    assert_equal ["tmux", "-u", "attach-session", "-t", "=#{session}"], events.last
  end

  def test_saved_claude_conversation_uses_native_resume
    _, error, status = launch("claude", "xps", "--resume", "saved-id")
    assert status.success?, error
    assert_equal ["claude", @remote_home, "--resume", "saved-id"], events.find { |event| event.first == "claude" }
  end

  def test_reattaching_does_not_start_another_claude_process
    _, error, status = launch("claude", "xps", "--attach", "claude-existing")
    assert status.success?, error
    assert_equal ["tmux", "-u", "attach-session", "-t", "=claude-existing"], events.last
    refute events.any? { |event| event.first == "claude" }
  end

  def test_sessions_lists_only_launcher_terminals_without_starting_an_agent
    output, error, status = launch("claude", "framework", "--sessions")
    assert status.success?, error
    assert_includes output, "claude-existing"
    assert_includes events.last, '#{m:claude-*,#{session_name}}'
    refute events.any? { |event| event.first == "claude" }
  end

  def test_native_background_agents_can_be_listed_without_a_terminal
    _, error, status = launch("claude", "framework", "agents", "--json")
    assert status.success?, error
    assert_includes events.first, "-T"
    refute events.any? { |event| event.first == "tmux" }
  end

  def test_invalid_devices_cannot_be_ssh_options_or_shell_commands
    ["-oProxyCommand=touch /tmp/no", "framework;touch /tmp/no", "$(hostname)"].each do |device|
      _, _, status = launch("codex", device)
      refute status.success?
    end
    assert_empty events
  end
end
