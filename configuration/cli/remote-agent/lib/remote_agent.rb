require "open3"
require "securerandom"
require "shellwords"
require "tmpdir"

module RemoteAgent
  REMOTE_PATH = 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'.freeze
  SSH_OPTIONS = ["-o", "ConnectTimeout=10", "-o", "ServerAliveInterval=15"].freeze
  DEVICE_PATTERN = /\A(?:[a-zA-Z0-9_][a-zA-Z0-9_.-]*@)?[a-zA-Z0-9][a-zA-Z0-9.-]*\z/
  SESSION_PATTERN = /\Aclaude-[a-zA-Z0-9-]+\z/

  module_function

  def run(agent, arguments)
    if arguments.empty? || ["--help", "-h"].include?(arguments.first)
      puts usage(agent)
      return arguments.empty? ? 1 : 0
    end

    device, *agent_arguments = arguments
    raise ArgumentError, "Use a tailnet device name, hostname, or user@hostname." unless DEVICE_PATTERN.match?(device)

    agent == "codex" ? codex(device, agent_arguments) : claude(device, agent_arguments)
  rescue ArgumentError, SystemCallError, RuntimeError => error
    warn error.message
    1
  end

  def usage(agent)
    common = "Usage: #{agent}-on DEVICE [agent arguments]\n\nDEVICE can be framework, xps, or user@hostname. No arguments starts a new session.\n"
    return common + "Use resume --all to browse conversations, or resume SESSION_ID to reconnect.\nUse -C ~/code/project to choose a directory on the destination.\n" if agent == "codex"

    common + <<~HELP
      --cd PATH          Choose a directory on the destination (before agent arguments).
      --sessions         List persistent terminal sessions on the destination.
      --attach NAME      Reattach a terminal listed by --sessions.
      --resume [ID]      Use Claude's saved conversation picker or resume an ID.
      Other arguments are passed to Claude, including agents and attach for native background agents.
    HELP
  end

  def command_status(*command, **options)
    system(*command, **options)
    status = $?
    status.exitstatus || 128 + status.termsig
  end

  def codex(device, arguments)
    preparation = <<~SH
      #{REMOTE_PATH}
      codex app-server daemon start >/dev/null || exit
      printf '%s\n' "$HOME" "${CODEX_HOME:-$HOME/.codex}/app-server-control/app-server-control.sock"
    SH
    output, status = Open3.capture2("ssh", *SSH_OPTIONS, "-T", device, preparation)
    raise "Could not start Codex on #{device}. Check SSH access and the remote Codex installation." unless status.success?

    home, remote_socket, *unexpected = output.lines.map(&:chomp)
    unless unexpected.empty? && [home, remote_socket].all? { |path| path&.start_with?("/") && !path.include?(":") }
      raise "Unexpected Codex socket path from #{device}. Check for shell startup output."
    end

    Dir.mktmpdir("agent-on-", "/tmp") do |directory|
      control = File.join(directory, "ssh")
      socket = File.join(directory, "codex")
      forwarding = command_status("ssh", *SSH_OPTIONS, "-fNM", "-S", control,
                                  "-o", "ControlPersist=no", "-o", "ExitOnForwardFailure=yes",
                                  "-L", "#{socket}:#{remote_socket}", device)
      raise "Could not open the SSH tunnel to #{device}." unless forwarding.zero?

      begin
        has_directory = arguments.any? { |argument| argument == "--cd" || argument.start_with?("--cd=", "-C") }
        default_directory = has_directory ? [] : ["-C", home]
        command_status("codex", "--remote", "unix://#{socket}", *default_directory,
                       *codex_arguments(arguments, home))
      ensure
        command_status("ssh", "-S", control, "-O", "exit", device, out: File::NULL, err: File::NULL)
      end
    end
  end

  def codex_arguments(arguments, home)
    arguments.each_with_index.map do |argument, index|
      if index.positive? && ["-C", "--cd"].include?(arguments[index - 1])
        destination_path(argument, home)
      elsif argument.start_with?("--cd=")
        "--cd=#{destination_path(argument.delete_prefix('--cd='), home)}"
      else
        argument
      end
    end
  end

  def destination_path(path, home)
    return home if path == "~"
    return File.join(home, path.delete_prefix("~/")) if path.start_with?("~/")

    path
  end

  def remote_directory(path)
    return '"$HOME"' if path == "~"
    return '"$HOME"/' + Shellwords.escape(path.delete_prefix("~/")) if path.start_with?("~/")

    Shellwords.escape(path)
  end

  def claude(device, arguments)
    if arguments.first == "--sessions"
      raise ArgumentError, "Use --sessions without additional arguments." unless arguments.length == 1

      return command_status("ssh", *SSH_OPTIONS, "-T", device,
                            "#{REMOTE_PATH}; exec tmux list-sessions -f " +
                            Shellwords.escape('#{m:claude-*,#{session_name}}') +
                            " -F " + Shellwords.escape('#{session_name}  #{session_windows} window(s)  #{session_attached} attached'))
    end

    if arguments.first == "--attach"
      session = arguments[1]
      unless arguments.length == 2 && session && SESSION_PATTERN.match?(session)
        raise ArgumentError, "Use --attach with a claude-... name from --sessions."
      end

      return command_status("ssh", *SSH_OPTIONS, "-t", device,
                            "#{REMOTE_PATH}; exec tmux attach-session -t #{Shellwords.escape("=#{session}")}")
    end

    directory, remaining = claude_arguments(arguments)
    agent_command = "#{REMOTE_PATH}; cd #{remote_directory(directory)} && exec #{Shellwords.join(['claude', *remaining])}"
    if ["--help", "-h", "--version", "-v"].include?(remaining.first) ||
       (remaining.first == "agents" && remaining.include?("--json"))
      return command_status("ssh", *SSH_OPTIONS, "-T", device, agent_command)
    end

    session = "claude-#{SecureRandom.hex(6)}"
    warn "Reconnect with: claude-on #{device} --attach #{session}"
    creation = Shellwords.join(["tmux", "new-session", "-d", "-s", session, agent_command])
    attachment = Shellwords.join(["tmux", "attach-session", "-t", "=#{session}"])
    command_status("ssh", *SSH_OPTIONS, "-t", device, "#{REMOTE_PATH}; #{creation} && exec #{attachment}")
  end

  def claude_arguments(arguments)
    return ["~", arguments] unless arguments.first == "--cd"

    raise ArgumentError, "--cd needs a destination directory." unless arguments[1] && !arguments[1].empty?

    [arguments[1], arguments.drop(2)]
  end
end
