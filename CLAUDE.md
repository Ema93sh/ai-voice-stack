# AI Voice Stack

Local push-to-talk dictation + Kokoro TTS for Ubuntu.

## Repo Structure

- `scripts/` — all executable scripts (bash + python)
  - `dictation-lib.sh` — shared functions sourced by dictate-start/stop
  - `dictate-start` / `dictate-stop` — push-to-talk recording lifecycle
  - `ai-say` — TTS entry point (Kokoro → flite → spd-say fallback chain)
  - `kokoro-synthesize.py` — Kokoro WAV synthesis helper
  - `transcribe-audio` / `transcribe_whisper.py` — STT dispatch + local whisper
  - `voice-up-setup.sh` — one-command installer
  - `voice-up-container-test.sh` — Docker-based validation
  - `voice-status` — diagnostic status reporter
  - `run-tests.sh` — shellcheck + unit tests
- `config/` — sample config files (xbindkeysrc, ai-audio.env)
- `docs/` — setup, usage, env vars, troubleshooting, voices
- `.agents/skills/ai-say/` — Claude Code skill for TTS

## Conventions

- Shell scripts use `#!/usr/bin/env bash` and `set -euo pipefail`
- State lives under `${XDG_RUNTIME_DIR:-/tmp}/dictation` (or `/ai-say`)
- User config: `~/.config/ai-audio.env` (sourced at script start)
- Scripts install to `~/.local/bin/`; kokoro artifacts to `~/.local/share/kokoro-tts/`
- Environment variables are documented in `docs/ENV_VARS.md`

## Testing

```bash
# Lint all shell scripts
scripts/run-tests.sh

# Docker-based install validation
scripts/voice-up-container-test.sh        # quick mode
scripts/voice-up-container-test.sh full   # full Python validation
```

## Common Tasks

```bash
# Install everything
scripts/voice-up-setup.sh --with-system-deps

# Diagnostics
scripts/voice-status

# TTS test
~/.local/bin/ai-say "Hello"
```
