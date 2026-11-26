# Coding agents on another device

Use a tailnet device name with either launcher. Both directions work; the
destination owns the files, agent login, and conversation history.

```sh
codex-on framework
codex-on xps -C '~/code/otto'
codex-on framework resume --all
codex-on framework resume SESSION_ID

claude-on framework
claude-on xps --cd '~/code/otto'
claude-on framework --resume
claude-on framework --resume SESSION_ID
```

No arguments after the device starts a new conversation. Use the agent's
resume command to return to saved conversations. Quote `~/...` paths so they
expand on the destination. Absolute paths refer to the destination too.
Use `other-user@device` when the remote username differs. SSH configuration,
host verification, and existing SSH authentication apply normally.

## Staying connected

Codex runs its interface locally and connects to the destination's existing
app-server daemon through a private Unix socket forwarded by SSH. It starts
the daemon if needed, without restarting one that is already running.
Closing the interface cleans up the tunnel; the remote daemon remains alive.
This needs compatible Codex versions supporting `--remote unix://PATH` on
both machines. No Tailscale Serve endpoint, shared token, or public port is
required. The local temporary directory is private to your user.

Claude runs its terminal interface over SSH inside a persistent tmux session.
The launcher prints a reconnect command before connecting. If the laptop
disconnects or restarts, find and reconnect to that terminal:

```sh
claude-on framework --sessions
claude-on framework --attach claude-SESSION_NAME
```

Detach with tmux's prefix followed by `d` (`Ctrl+A`, then `d` in Orchard).
Exiting Claude ends that terminal; `--resume` can reopen the saved conversation.
Use `--attach` for a live terminal so you do not start a second process writing
the same conversation. These terminals survive client disconnects, not a
reboot of the destination.

Claude's native background sessions are separate and remain available:

```sh
claude-on framework agents --json
claude-on framework attach BACKGROUND_SESSION_ID
```

Existing foreground sessions started outside these launchers cannot be
adopted into tmux. Finish or exit those before resuming their saved history.
Native background attachment and saved-session resume have different
semantics; see [Claude sessions](https://code.claude.com/docs/en/sessions).

## Otto's conversations

Otto names each conversation after its first request and keeps it running in
a tmux window on the server. List them, or open one's live terminal:

```sh
otto-on framework
otto-on framework perch-search-focus
```

Names tab-complete after the device. Opening a conversation gives you your own
view of Otto's terminals, so switching windows doesn't change what anyone else
sees; detach with the tmux prefix followed by `d` and the conversation keeps
running. Type there only while Otto isn't working on a reply.

## Setup and checks

Orchard's normal configuration links the launchers. To apply only these links:

```sh
bash configuration/cli/remote-agent/install.sh
```

The client needs Ruby and OpenSSH. The destination needs SSH access and the
chosen agent installed and signed in; Claude also needs tmux. Orchard already
provides these dependencies. Keep the destination awake and Tailscale connected.
The helpers also work with other SSH-reachable hostnames.

Run the launcher checks with Ruby and Minitest:

```sh
ruby configuration/cli/remote-agent/tests/launchers_test.rb
ruby configuration/cli/remote-agent/tests/otto_on_test.rb
```
