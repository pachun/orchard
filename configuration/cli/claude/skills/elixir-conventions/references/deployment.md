# Elixir deployment

Read the current `~/code/emma_api/.github/workflows/main.yml`, runtime
pins, release configuration, and official documentation before setup.

## Default: Gigalixir

For an ordinary hosted Phoenix application, use GitHub Actions to check
the exact revision and deploy it to its own Gigalixir application after
checks pass, following Emma API's workflow intent. Pull requests run
checks only. Deploy the configured release branch, normally `main`;
serialize deployments without canceling one halfway through.

Use pinned Elixir/OTP versions and locked dependencies. Add a CI database
only when needed. Do not copy Emma API's app name, credentials, database
version, old action versions, or deployment of a newer `main` revision
than the one checked. Configure the project's real application and CI
credentials using Gigalixir's current supported workflow.

Use `mix check` as the gate and retain useful failure artifacts. Initial
and multi-commit pushes must work. Distinguish building, deploying, and
verifying the running application.

## Explicit alternative: a user's own machine

Otto lives on the machine that owns its repositories, agent sign-ins,
tmux sessions, and tailnet access: initially the Framework. Keep GitHub
checks, but replace Gigalixir deployment with a local release installation
and service restart. Do not provision a cloud application just to mirror
Emma API's workflow.

Package the server as an Elixir release. On Linux, use systemd under the
intended unprivileged user. Keep secrets outside the checkout. Keep tmux
and agent processes outside the server service's lifecycle so restarting
the web server does not terminate ongoing conversations.

Document the authenticated HTTP/WebSocket entry point separately from
tailnet access to deployment targets. Tailscale membership alone does
not authenticate a public application endpoint.

Choose an automated deployment transport the host actually supports and
authorize/configure it in the task. Do not execute pull-request code on
the personal runner. Missing runners, credentials, or host permissions
are unfinished setup, not successful deployment. Never use sudo as the
agent; give Nick the exact privileged step when unavoidable.

- https://docs.gigalixir.com/deploy/
- https://phoenix.hexdocs.pm/releases.html
