# Stable Remake downloads

Stable adds decision-only model routing, subscription/API selection, native harness switching, and local usage reports to Claude Code, Codex, and Pi. Install the native hosts you want to use separately. No Palm, Conifer CLI, Go, or database server is needed.

```sh
curl -fsSL https://raw.githubusercontent.com/ConiferKit/stable-remake-releases/main/install.sh | sh
```

Supports macOS/Linux on arm64/amd64. The installer verifies the archive checksum, installs `~/.local/bin/stable`, and adds reversible bash/zsh integration. If no Conifer API key is configured, it opens [the Conifer console](https://conifer.build/console#/keys) and asks you to paste one (hidden input; press Enter to skip, since subscriptions work without a key). Open a new shell or source `~/.zshrc` / `~/.bashrc`. To skip shell integration, use `| sh -s -- --no-shell`; to skip the key prompt, `--no-login`. To select another prefix, use `| sh -s -- --prefix /absolute/path`.

```sh
stable login               # open the console, paste a key (hidden), verify, save
stable login --stdin       # or pipe the key; never put it in arguments
stable codex --model beta-router
stable claude --model beta-router
stable report
stable report --all --json
stable update --check
```

Native subscriptions use `codex login` or `claude auth login`. After shell integration, ordinary `codex` / `claude` / `pi` launches use Stable. Authentication and maintenance commands pass through unchanged.

```sh
stable codex --disable     # normal codex runs natively
stable codex --enable      # normal codex uses Stable
stable claude --disable
stable claude --enable
stable codex               # explicit Stable launch regardless of preference
stable claude --native     # explicit native bypass
stable shell remove        # remove owned startup blocks
```

## Native controls

| Feature | Codex | Claude / Pi |
|---|---|---|
| Model | `/model` picker | `/model` |
| Harness | `$stable:harness claude` | `/harness codex` |

Destination hosts must be installed. Handoffs carry visible user/assistant history and start with conservative permissions. Native tool approvals remain in force.

Since rc.5, the native model menus show the complete authorized Stable catalog in Router → Subscription → API order, including ChatGPT models in Claude. Claude requires 2.1.251 or later; its Default row follows Stable's configured default and native organization restrictions still apply. Codex shows connection labels in row descriptions. Pi shows `stable-router`, `stable-subscription`, and `stable-api` badges, with the complete Stable scope independent of saved native filters. Pi 0.73.1 and 0.87.0 are tested.

Since rc.6, selecting a model with Claude `/model` keeps the same process, conversation, and permission mode. Stable refreshes context and output limits through private watched settings and waits for Claude to acknowledge them before the next inference request. An unsuccessful refresh keeps the session open and blocks inference until another model selection recovers it. Original user settings remain untouched.

After updating, open a fresh `stable claude`, `stable codex`, or `stable pi` session and run `/model`. Active sessions are preserved on their original version. If ChatGPT subscription models are absent from `stable models` itself, run `codex login` first.

Since rc.9, model lists show `beta-router` (the default) followed by ranked subscription and API models; promoted models are marked "Suggested" and can be adjusted with `~/.stable-remake/rankings.json` (`{"subscription": [...], "api": [...]}`, exact IDs or globs). In interactive sessions, a routed turn starts with a line such as `↳ beta-router → glm-5.3-flash · API`; it is shown to you only. `codex resume --last` and `codex resume` also find sessions started without Stable and continue them through Stable. The reviewer is not part of this release.

After installation, ordinary `claude`, `codex`, and `pi` in bash/zsh use Stable by default; open a new terminal once. Since rc.8, if the Stable launcher is missing these commands say so (with the reinstall command) and run natively instead of silently skipping Stable, and `stable uninstall` removes the integration it installed.

Since rc.7, an exhausted gateway balance or missing key never blocks subscription use: router turns fall back to a subscription model at no fee, Claude subscriptions work without the gateway catalog, and Claude Code / Codex show their own usage-limit and reset messages. `claude --continue/--resume`, piped output (`claude | tee log`), and symlinked dotfiles now work through Stable.

## Usage and billing

**Stable does not charge for subscription execution.** Requests go directly to the native subscription provider. Reports remain local and are never sent to a billing endpoint. Exhausted quota or lost login never triggers a paid API fallback. Subscription plan fees and provider-enabled extra usage remain governed by the provider's account settings.

Router decisions have the gateway's separate routing fee. API-only models have normal API execution charges. `stable report` separates these from subscription usage and records only provider-reported tokens and settled cost receipts. Missing receipts are unknown, not free. The beta decision endpoint currently does not expose its settled fee; those decisions are reported with unknown cost. Plan invoices, activity outside Stable, and pre-rc.4 usage are not available.

## Updates and recovery

Updates install automatically in the background, verifying signed metadata and archive/binary hashes. Existing conversations continue on their original version; new launches use the update. No conversation is stopped for installation. Set `auto_update: false` in `~/.stable-remake/config.json` to disable this, or run `stable update` manually.

Unexpected native-host exits get up to two resume attempts without replaying the initial prompt. Normal exits and Ctrl-C are preserved. Set `auto_restart: false` to disable. OS-killed Stable processes and persistent bugs require manual recovery.

This repository contains distribution files only; all application logic is maintained in the private `ConiferKit/stable_remake` monorepo. Release candidates have targeted native and fault verification; extended production soak qualification remains open. See each release's notes for source provenance and test scope.
