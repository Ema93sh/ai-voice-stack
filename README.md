# AI Voice Stack (Dictation + Kokoro TTS)

Complete local voice workflow for Ubuntu:
- Push-to-talk dictation into terminal/tmux/chat inputs
- Dictation provider switch (`faster-whisper`, `openai`, `deepgram`)
- Local text-to-speech with Kokoro (`hexgrad/Kokoro-82M`) and fallbacks
- Stable hotkey setup, debouncing, logging, and tmux integration

This repo documents the full working setup and includes the exact scripts currently in use.

## Fast Install (One Command)

From this repo root:

```bash
scripts/voice-up-setup.sh --with-system-deps
```

If you already installed apt dependencies, use:

```bash
scripts/voice-up-setup.sh
```

## Dictation Providers

Default (local):

```bash
export DICTATION_PROVIDER=faster-whisper
```

OpenAI:

```bash
export DICTATION_PROVIDER=openai
export OPENAI_API_KEY="sk-..."
export DICTATION_OPENAI_MODEL="gpt-4o-mini-transcribe"
```

Deepgram:

```bash
export DICTATION_PROVIDER=deepgram
export DEEPGRAM_API_KEY="..."
export DICTATION_DEEPGRAM_MODEL="nova-3"
```

Apply config changes:

```bash
source ~/.config/ai-audio.env
```

## Container Test (One Command)

Run an isolated Ubuntu 24.04 validation in Docker:

```bash
scripts/voice-up-container-test.sh
```

Modes:
- `quick` (default): validates install path without Python package downloads
- `full`: runs full setup and verifies `faster-whisper` + `kokoro` imports
- `both`: runs `quick` then `full`

```bash
# Full dependency validation
scripts/voice-up-container-test.sh full
```

Then test:

```bash
~/.local/bin/ai-say "Voice test"
```

## What This Solves

- System-wide-ish dictation using a hold key (`Menu` key) with switchable STT providers
- Reliable text insertion into tmux panes
- Optional automatic submit (Enter/Ctrl+Enter)
- Local TTS playback on selected sink
- Better TTS quality with Kokoro, with fallback to flite and speech-dispatcher
- Diagnostics and recovery for stuck push-to-talk behavior

## Current Environment Snapshot

- OS: Ubuntu 24.04 (kernel 6.17.0-14-generic)
- Session: X11 (xbindkeys + xdotool active)
- Input mic: `alsa_input.usb-HP__Inc_HyperX_SoloCast-00.analog-stereo`
- Output sink: `alsa_output.pci-0000_f1_00.1.hdmi-stereo`
- Dictation providers: `faster-whisper` (local), `openai`, `deepgram`
- TTS model: `Kokoro-82M` (default voice `af_bella`)

## Skill Install

```bash
npx skills add Ema93sh/ai-voice-stack
```

## Repo Layout

- `scripts/`
  - `voice-up-setup.sh` — one-command installer
  - `voice-up-container-test.sh` — Docker-based validation
  - `dictation-lib.sh` — shared functions for dictation scripts
  - `dictate-start` / `dictate-stop` — push-to-talk lifecycle
  - `dictation-hotkeys` — xbindkeys restart helper
  - `transcribe_whisper.py` / `transcribe-audio` — STT dispatch
  - `ai-say` / `ai-tts-last` — TTS entry points
  - `kokoro-synthesize.py` — Kokoro WAV synthesis
  - `voice-status` — diagnostic status reporter
  - `run-tests.sh` — shellcheck + unit tests
  - `install-hooks.sh` / `pre-commit-hook.sh` — git hooks
- `config/`
  - `xbindkeysrc.sample`
  - `ai-audio.env.sample`
- `docs/`
  - `SETUP.md`
  - `USAGE.md`
  - `ENV_VARS.md`
  - `TROUBLESHOOTING.md`
  - `DECISIONS.md`
  - `VOICES.md`

## Daily Commands

```bash
# Check stack health
~/.local/bin/voice-status

# Restart keybindings
~/.local/bin/dictation-hotkeys

# Speak with default Kokoro voice
~/.local/bin/ai-say "Hello world"

# Temporary voice override
AI_KOKORO_VOICE=am_michael ~/.local/bin/ai-say "Voice test"

# Check dictation logs
tail -f ${XDG_RUNTIME_DIR:-/run/user/1000}/dictation/dictation.log
```

## Important Notes

- Push-to-talk is keycode-only in xbindkeys: `c:135` with fallback `c:147` (no Mod2 dependency).
- The dictation stack is stateful under `${XDG_RUNTIME_DIR}/dictation`.
- `dictate-stop` includes repeat-keyup debounce and minimum-hold checks to prevent stuck loops.
- TTS is Kokoro-first and auto-boosts volume before playback.

## License

MIT License. See [LICENSE](LICENSE).
