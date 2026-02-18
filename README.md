# AI Voice Stack

Talk to your terminal. Have it talk back.

**Hold a key, speak, release** — your words appear at the cursor. Ask your AI
agent to respond and **hear it out loud** in a natural voice. Everything runs
locally on your machine. No cloud required, no latency, no subscription.

- **Push-to-talk dictation** — hold Menu key, speak, release. Text lands in
  your terminal, tmux pane, or chat input. Works with `faster-whisper` (local),
  OpenAI, or Deepgram.
- **Local TTS** — high-quality speech powered by
  [Kokoro](https://huggingface.co/hexgrad/Kokoro-82M) (82M params, 50+ voices,
  8 languages). Falls back to flite and espeak-ng automatically.
- **Agent skill included** — install the skill and your AI coding agent (Claude
  Code, Cursor, etc.) learns to speak on its own. No prompt engineering needed.
- **Zero config** — one command installs everything. Hotkeys, Python envs,
  audio routing, and tmux integration are handled for you.

## Quick Start

### 1. Install the voice stack

```bash
git clone https://github.com/Ema93sh/ai-voice-stack.git
cd ai-voice-stack
scripts/voice-up-setup.sh --with-system-deps
```

Skip `--with-system-deps` if you already have the apt packages.

### 2. Try it

```bash
# Speak something
~/.local/bin/ai-say "Hello from the terminal"

# Hold Menu key → speak → release → text appears at cursor

# Try a different voice
AI_KOKORO_VOICE=am_fenrir ~/.local/bin/ai-say "Voice test"

# Check installation health
bash skills/ai-say/scripts/doctor.sh
```

### 3. Give your AI agent a voice

```bash
npx skills add Ema93sh/ai-voice-stack
```

This installs the **ai-say** skill into Claude Code, Cursor, Windsurf, or any
agent that supports the [skills](https://github.com/vercel-labs/skills) format.
After install, your agent can call `~/.local/bin/ai-say` on its own — it learns
the commands, the voice catalog, and the debug flow from the skill file.

Ask Claude Code to *"read that back to me"* or *"say hello"* and it will speak
through your speakers. No prompt engineering, no explaining the commands — the
skill handles it.

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

## Agent Skill

Once the skill is installed (`npx skills add Ema93sh/ai-voice-stack`), your
agent knows how to:

- Speak text aloud: `~/.local/bin/ai-say "text"`
- Pipe output to speech: `echo "hello" | ~/.local/bin/ai-say`
- Switch voices: `AI_KOKORO_VOICE=am_fenrir ~/.local/bin/ai-say "test"`
- Diagnose audio issues: `~/.local/bin/voice-status`
- Browse 50+ Kokoro voices and adjust gain/volume

Manage installed skills:

```bash
npx skills list          # show installed skills
npx skills check         # check for updates
npx skills update        # update all skills
npx skills remove ai-say # uninstall
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
- `skills/`
  - `ai-say/` — installable agent skill for TTS
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
