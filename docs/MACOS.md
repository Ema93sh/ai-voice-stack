# macOS Setup Guide

AI Voice Stack runs on macOS with some differences from Linux.

## Prerequisites

- **macOS 12 (Monterey)** or later
- **Homebrew** — install from https://brew.sh
- **Python 3.10+** — `brew install python` (or use an existing install)
- **ffmpeg** — `brew install ffmpeg`

## Installation

```bash
# Install everything (system deps + Python envs)
scripts/voice-up-setup.sh --with-system-deps

# Or skip system deps if you already have them
scripts/voice-up-setup.sh
```

The installer will use `brew install` instead of `apt` on macOS and skip
Linux-only config files like `.xbindkeysrc`.

## TTS (ai-say)

TTS works out of the box. The fallback chain is:

1. **Kokoro** (neural TTS) — same as Linux
2. **`say`** (built-in macOS TTS) — replaces `spd-say`/`flite`

The `flite` fallback is skipped on macOS since it's a Linux library.

Test it:

```bash
~/.local/bin/ai-say "Hello from macOS"
```

## Dictation Hotkeys with Karabiner-Elements

On Linux, `xbindkeys` maps a key to dictate-start/stop. On macOS, use
[Karabiner-Elements](https://karabiner-elements.pqrs.org/) instead.

### Step 1: Install Karabiner-Elements

```bash
brew install --cask karabiner-elements
```

Grant Accessibility permissions when prompted (System Settings > Privacy &
Security > Accessibility).

### Step 2: Import the dictation rule

Copy the provided config into Karabiner's complex modifications directory:

```bash
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp config/karabiner-dictation.json \
   ~/.config/karabiner/assets/complex_modifications/dictation.json
```

### Step 3: Enable the rule

1. Open Karabiner-Elements Preferences
2. Go to **Complex Modifications** tab
3. Click **Add rule**
4. Find "Hold right_option for push-to-talk dictation" and enable it

Now hold **Right Option** to record, release to transcribe and insert.

### Customizing the trigger key

Edit the `from.key_code` field in `karabiner-dictation.json` to change the
trigger key. Common choices:

| Key | `key_code` value |
|---|---|
| Right Option | `right_option` |
| Right Command | `right_command` |
| Caps Lock | `caps_lock` |
| F18 | `f18` |

## Accessibility Permissions

Dictation needs to insert text into the active application. On macOS this
requires **Accessibility** permissions for `osascript` (or Terminal/iTerm2).

1. Open **System Settings > Privacy & Security > Accessibility**
2. Add your terminal app (Terminal.app, iTerm2, etc.)

Without this permission, text insertion via `osascript` keystroke simulation
will silently fail. The tmux paste-buffer path works without extra permissions.

## Environment Variables

macOS-specific variables (set in `~/.config/ai-audio.env`):

| Variable | Default | Description |
|---|---|---|
| `DICTATION_AVFOUNDATION_INDEX` | `:default` | AVFoundation audio input device index for ffmpeg recording |

All other environment variables documented in `docs/ENV_VARS.md` work the same
on macOS.

## Known Differences from Linux

| Feature | Linux | macOS |
|---|---|---|
| Audio playback | `paplay` (PulseAudio) | `afplay` |
| Audio recording | `ffmpeg -f pulse` | `ffmpeg -f avfoundation` |
| Sink/source control | `pactl` | No-op (use System Settings) |
| TTS fallback | `spd-say` (espeak-ng) | `say` (built-in) |
| Text insertion | `xdotool`/`ydotool` | `pbcopy` + `osascript` Cmd+V |
| Hotkey daemon | `xbindkeys` | Karabiner-Elements |
| Millisecond timestamps | `date +%s%3N` | `python3 time.time()` |
| `flock` | Built-in | `brew install flock` |
