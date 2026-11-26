require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"

class OttoOnTest < Minitest::Test
  FEATURE = File.expand_path("..", __dir__)
  SECONDS_PER_MINUTE = 60
  SECONDS_PER_HOUR = 3600

  def setup
    @directory = Dir.mktmpdir("otto-on-test-")
    @bin = File.join(@directory, "bin")
    @events = File.join(@directory, "events")
    FileUtils.mkdir_p(@bin)
    now = Time.now.to_i
    windows = [
      ["", "runner", "", now],
      ["phone-1", "perch-search-focus", "", now - 5 * SECONDS_PER_MINUTE],
      ["phone-2", "aviary-download-order", "claude", now - 2 * SECONDS_PER_HOUR],
      ["phone-3", "phone-3", "", now],
      ["phone-4", "otto-long-requests", "", now - 30]
    ].map { |fields| fields.join("\t") }.join("\n")
    @environment = {
      "PATH" => "#{@bin}:#{ENV.fetch('PATH')}",
      "OTTO_TEST_EVENTS" => @events,
      "OTTO_TEST_WINDOWS" => windows
    }
    executable("ssh", <<~'RUBY')
      require "json"
      File.open(ENV.fetch("OTTO_TEST_EVENTS"), "a") { |file| file.puts(JSON.generate(["ssh", *ARGV])) }
      exit 255 if ENV["OTTO_TEST_SSH_FAIL"]
      exec "sh", "-c", ARGV.last
    RUBY
    executable("tmux", <<~'RUBY')
      require "json"
      File.open(ENV.fetch("OTTO_TEST_EVENTS"), "a") { |file| file.puts(JSON.generate(["tmux", *ARGV])) }
      case ARGV.first
      when "list-windows" then puts ENV.fetch("OTTO_TEST_WINDOWS")
      when "new-session" then exit(ENV["OTTO_TEST_NOT_RUNNING"] ? 1 : 0)
      when "select-window" then exit(ARGV.last.end_with?("=perch-search-focus") ? 0 : 1)
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

  def otto_on(*arguments, environment: {})
    Open3.capture3(@environment.merge(environment), File.join(FEATURE, "bin", "otto-on"), *arguments)
  end

  def events
    File.exist?(@events) ? File.readlines(@events).map { |line| JSON.parse(line) } : []
  end

  def test_lists_named_conversations_newest_first_with_their_agent
    output, error, status = otto_on("framework")
    assert status.success?, error
    assert_equal <<~LIST, output
      otto-long-requests     codex   just now
      perch-search-focus     codex   5 minutes ago
      aviary-download-order  claude  2 hours ago
    LIST
    assert_includes events.find { |event| event.first == "ssh" }, "framework"
  end

  def test_lists_only_names_for_completion
    output, error, status = otto_on("framework", "--names")
    assert status.success?, error
    assert_equal "otto-long-requests\nperch-search-focus\naviary-download-order\n", output
  end

  def test_opens_the_named_conversation_in_its_own_view_of_ottos_terminals
    _output, error, status = otto_on("framework", "perch-search-focus")
    assert status.success?, error
    ssh = events.find { |event| event.first == "ssh" }
    assert_includes ssh, "-t"
    tmux = events.select { |event| event.first == "tmux" }.map { |event| event.drop(1) }
    view = tmux.find { |arguments| arguments.first == "new-session" }.then { |arguments| arguments[arguments.index("-s") + 1] }
    assert_match(/\Aotto-view-[0-9a-f]+\z/, view)
    assert_equal ["new-session", "-d", "-t", "otto", "-s", view], tmux.at(0)
    assert_equal ["select-window", "-t", "#{view}:=perch-search-focus"], tmux.at(1)
    assert_equal ["set-option", "-t", view, "destroy-unattached", "on"], tmux.at(2)
    assert_equal ["attach-session", "-t", "=#{view}"], tmux.at(3)
  end

  def test_says_when_no_conversation_has_that_name
    _output, error, status = otto_on("framework", "missing-conversation")
    refute status.success?
    assert_includes error, "No Otto conversation named missing-conversation on framework."
    assert(events.any? { |event| event[0, 2] == ["tmux", "kill-session"] })
  end

  def test_says_when_otto_is_not_running_on_the_device
    _output, error, status = otto_on("framework", "perch-search-focus",
                                     environment: { "OTTO_TEST_NOT_RUNNING" => "1" })
    refute status.success?
    assert_includes error, "Otto isn't running on framework."
  end

  def test_says_when_the_device_cannot_be_reached
    _output, error, status = otto_on("framework", environment: { "OTTO_TEST_SSH_FAIL" => "1" })
    refute status.success?
    assert_includes error, "Could not reach Otto on framework."
  end

  def test_rejects_a_name_otto_would_never_give
    _output, error, status = otto_on("framework", "not a name")
    refute status.success?
    assert_includes error, "Use a conversation name from otto-on framework."
    assert_empty events
  end

  def test_explains_itself_without_a_device
    output, _error, status = otto_on
    refute status.success?
    assert_includes output, "Usage: otto-on DEVICE [NAME]"
  end
end
