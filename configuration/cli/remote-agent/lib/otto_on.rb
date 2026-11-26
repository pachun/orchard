require "open3"
require "securerandom"
require "shellwords"
require_relative "remote_agent"

module OttoOn
  NAME_PATTERN = /\A[a-z0-9][a-z0-9-]*\z/
  OTTO_SESSION = "otto".freeze
  SECONDS_PER_MINUTE = 60
  SECONDS_PER_HOUR = 3600
  SECONDS_PER_DAY = 86_400
  WINDOW_FORMAT = '#{@otto-session}' + "\t" + '#{window_name}' + "\t" +
                  '#{@otto-harness}' + "\t" + '#{window_activity}'

  Conversation = Struct.new(:name, :harness, :active_at)

  module_function

  def run(arguments)
    device, name = arguments
    if device.nil? || ["--help", "-h"].include?(device) || arguments.length > 2
      puts usage
      return device.nil? || arguments.length > 2 ? 1 : 0
    end
    raise ArgumentError, "Use a tailnet device name, hostname, or user@hostname." unless RemoteAgent::DEVICE_PATTERN.match?(device)

    case name
    when nil then list(device)
    when "--names" then list_names(device)
    when NAME_PATTERN then open(device, name)
    else raise ArgumentError, "Use a conversation name from otto-on #{device}."
    end
  rescue ArgumentError, SystemCallError, RuntimeError => error
    warn error.message
    1
  end

  def usage
    <<~HELP
      Usage: otto-on DEVICE [NAME]

      With only DEVICE, lists Otto's named conversations there, newest first.
      With NAME, opens that conversation's live terminal. Detach with the tmux
      prefix followed by d; the conversation keeps running.
    HELP
  end

  def list(device)
    conversations = conversations_on(device)
    width = conversations.map { |conversation| conversation.name.length }.max.to_i
    harness_width = conversations.map { |conversation| conversation.harness.length }.max.to_i
    conversations.each do |conversation|
      puts "#{conversation.name.ljust(width)}  #{conversation.harness.ljust(harness_width)}  #{ago(conversation.active_at)}"
    end
    0
  end

  def list_names(device)
    conversations_on(device).each { |conversation| puts conversation.name }
    0
  end

  def conversations_on(device)
    command = "#{RemoteAgent::REMOTE_PATH}; tmux list-windows -t #{OTTO_SESSION} -F #{Shellwords.escape(WINDOW_FORMAT)}"
    output, status = Open3.capture2("ssh", *RemoteAgent::SSH_OPTIONS, "-T", device, command)
    raise "Could not reach Otto on #{device}." unless status.success?

    output.lines(chomp: true)
          .map { |line| line.split("\t", -1) }
          .select { |phone_session, name, _harness, _activity| !phone_session.to_s.empty? && name != phone_session }
          .map { |_phone_session, name, harness, activity| Conversation.new(name, harness.to_s.empty? ? "codex" : harness, Integer(activity)) }
          .sort_by { |conversation| -conversation.active_at }
  end

  def ago(active_at)
    elapsed = Time.now.to_i - active_at
    if elapsed < SECONDS_PER_MINUTE then "just now"
    elsif elapsed < SECONDS_PER_HOUR then plural(elapsed / SECONDS_PER_MINUTE, "minute")
    elsif elapsed < SECONDS_PER_DAY then plural(elapsed / SECONDS_PER_HOUR, "hour")
    else plural(elapsed / SECONDS_PER_DAY, "day")
    end
  end

  def plural(count, unit)
    "#{count} #{unit}#{count == 1 ? '' : 's'} ago"
  end

  def open(device, name)
    view = "otto-view-#{SecureRandom.hex(4)}"
    view_target = Shellwords.escape("=#{view}")
    script = <<~SH
      #{RemoteAgent::REMOTE_PATH}
      tmux new-session -d -t #{OTTO_SESSION} -s #{view} || { echo "Otto isn't running on #{device}." >&2; exit 1; }
      if tmux select-window -t #{Shellwords.escape("#{view}:=#{name}")}; then
        tmux set-option -t #{view} destroy-unattached on
        exec tmux attach-session -t #{view_target}
      else
        tmux kill-session -t #{view_target}
        echo "No Otto conversation named #{name} on #{device}." >&2
        exit 1
      fi
    SH
    RemoteAgent.command_status("ssh", *RemoteAgent::SSH_OPTIONS, "-t", device, script)
  end
end
