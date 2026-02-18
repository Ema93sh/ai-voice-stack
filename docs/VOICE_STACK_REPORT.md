# Voice Stack Detailed Report

## Scope

This report documents the implemented Ubuntu voice stack for:
- Push-to-talk dictation (Whisper/faster-whisper)
- Local TTS playback (Kokoro-first, with fallbacks)
- tmux-aware insertion and submission behavior
- Stability fixes for stuck/random push-to-talk behavior

## Repository

- Repo: `/data/workstation/workspace/ubuntu-voice-hub`
- Skill added: `.agents/skills/ai-say`

## Environment Snapshot

- OS: Ubuntu 24.04 series
- Session path in use: X11 + `xbindkeys`
- Input source: `alsa_input.usb-HP__Inc_HyperX_SoloCast-00.analog-stereo`
- Output sink: `alsa_output.pci-0000_f1_00.1.hdmi-stereo`

## Implemented Components

### Dictation

- `scripts/dictate-start`
  - starts Pulse recording with `ffmpeg`
  - writes state under `${XDG_RUNTIME_DIR}/dictation`
  - records start timestamp and last keydown timestamp
  - supports timeout safety auto-stop

- `scripts/dictate-stop`
  - debounces synthetic repeat keyup events
  - enforces minimum hold duration
  - stops recorder cleanly, transcribes, inserts text
  - tmux-first insertion (`tmux paste-buffer`), then desktop fallback
  - attempts submit (`Enter` in tmux, Ctrl+Enter fallback path elsewhere)

- `scripts/transcribe_whisper.py`
  - uses `faster_whisper.WhisperModel`
  - defaults: `small.en`, `cpu`, `int8`

- `config/xbindkeysrc.sample`
  - final binding is keycode-only (no Mod2 dependency):
    - `c:135` + `release + c:135`
    - fallback `c:147` + `release + c:147`

### TTS

- `scripts/ai-say`
  - primary: Kokoro (`hexgrad/Kokoro-82M`)
  - playback: `paplay` to configured sink
  - gain/limiter boost applied for audibility
  - fallback 1: ffmpeg flite
  - fallback 2: speech-dispatcher (`spd-say`)

- `scripts/kokoro-synthesize.py`
  - local synthesis helper for Kokoro
  - writes WAV output at configured sample rate

- `scripts/ai-tts-last`
  - captures latest relevant tmux pane output
  - forwards text to `ai-say`

## Final User Config

- `~/.config/ai-audio.env`
  - `DICTATION_SOURCE` pinned to HyperX SoloCast
  - `AI_TTS_SINK` pinned to HDMI sink
  - `AI_KOKORO_VOICE` default set via fallback expansion:
    - `export AI_KOKORO_VOICE="${AI_KOKORO_VOICE:-af_bella}"`

This allows temporary per-command override, for example:

```bash
AI_KOKORO_VOICE=am_michael ~/.local/bin/ai-say "voice test"
```

## Key Issues Found and Resolved

1. Push-to-talk random/stuck triggering
- Cause: key event storm and synthetic keyup behavior while Menu was held
- Fixes:
  - keyup debounce (`DICTATION_KEYUP_DEBOUNCE_MS`)
  - hold threshold check before stopping recorder
  - keycode-only xbindkeys mapping with fallback keycode

2. TTS silent or inconsistent playback
- Cause: speech-dispatcher route instability and low Kokoro output loudness
- Fixes:
  - Kokoro-first path with direct WAV playback to pinned sink
  - gain/limiter preprocessing for Kokoro output
  - fallback chain kept for resilience

3. Voice override ignored
- Cause: exported hardcoded default in env file overwrote inline overrides
- Fix:
  - changed to parameter-expansion default pattern

## Validation Performed

- Confirmed sink/source discovery with `pactl`
- Confirmed direct tone playback on sinks
- Confirmed TTS playback with Kokoro on HDMI sink
- Confirmed short-text `ai-say` playback path execution
- Confirmed push-to-talk start/stop events logged after final binding update
- Confirmed no stuck recorder process (`rec.pid` clears after stop)

## Operational Commands

```bash
# Restart hotkeys
~/.local/bin/dictation-hotkeys

# Dictation logs
tail -f ${XDG_RUNTIME_DIR:-/run/user/1000}/dictation/dictation.log

# Speak text
~/.local/bin/ai-say "Hello"

# Temporary voice switch
AI_KOKORO_VOICE=am_fenrir ~/.local/bin/ai-say "Voice test"

# Device inventory
pactl list short sinks
pactl list short sources
pactl info | rg 'Default Sink|Default Source'
```

## Current Outcome

- Push-to-talk: working
- Dictation insertion: working (tmux-aware)
- TTS: working with Kokoro
- Default voice: `af_bella`

