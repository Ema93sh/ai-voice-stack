# Setup

## Fast Path (Recommended)

Run from repo root:

```bash
scripts/voice-up-setup.sh --with-system-deps
```

If apt dependencies are already installed:

```bash
scripts/voice-up-setup.sh
```

The setup script installs scripts/configs, creates Python environments, and restarts hotkeys.

## Container Test

Run a clean Ubuntu 24.04 validation in Docker:

```bash
scripts/voice-up-container-test.sh
```

Use `scripts/voice-up-container-test.sh full` for the complete Python dependency test (slower).

## Script Options

```bash
scripts/voice-up-setup.sh --help
```

Options:
- `--with-system-deps` install apt packages via sudo
- `--force-config` overwrite existing `~/.xbindkeysrc` and `~/.config/ai-audio.env`
- `--skip-python` skip venv/package install
- `--no-hotkeys` do not restart hotkeys at end

## Manual Setup (Fallback)

### 1) System Dependencies

```bash
sudo apt update
sudo apt install -y \
  portaudio19-dev python3-venv python3-pip git \
  xdotool ydotool pulseaudio-utils ffmpeg xbindkeys
```

### 2) Python Environments

#### Dictation (faster-whisper)

```bash
python3 -m venv ~/.venvs/dictation
~/.venvs/dictation/bin/pip install --upgrade pip
~/.venvs/dictation/bin/pip install faster-whisper
```

#### Kokoro TTS

```bash
python3.12 -m venv ~/.local/share/kokoro-tts/.venv
~/.local/share/kokoro-tts/.venv/bin/pip install --upgrade pip setuptools wheel
~/.local/share/kokoro-tts/.venv/bin/pip install kokoro soundfile
```

### 3) Install Scripts

```bash
mkdir -p ~/.local/bin ~/.local/share/kokoro-tts
cp scripts/dictate-start ~/.local/bin/
cp scripts/dictate-stop ~/.local/bin/
cp scripts/dictation-hotkeys ~/.local/bin/
cp scripts/transcribe_whisper.py ~/.local/bin/
cp scripts/transcribe-audio ~/.local/bin/
cp scripts/ai-say ~/.local/bin/
cp scripts/ai-tts-last ~/.local/bin/
cp scripts/kokoro-synthesize.py ~/.local/share/kokoro-tts/synthesize.py
chmod +x ~/.local/bin/dictate-start ~/.local/bin/dictate-stop ~/.local/bin/dictation-hotkeys \
  ~/.local/bin/transcribe_whisper.py ~/.local/bin/transcribe-audio ~/.local/bin/ai-say ~/.local/bin/ai-tts-last \
  ~/.local/share/kokoro-tts/synthesize.py
ln -sf ~/.local/bin/ai-say ~/.local/bin/ai-tts
```

### 4) Install Config

```bash
cp config/xbindkeysrc.sample ~/.xbindkeysrc
mkdir -p ~/.config
cp config/ai-audio.env.sample ~/.config/ai-audio.env
```

Edit `~/.config/ai-audio.env` and pin your source/sink names.

### 5) Start Hotkeys

```bash
~/.local/bin/dictation-hotkeys
```

## Verify

```bash
# Dictation: hold Menu key, speak, release.
# TTS:
~/.local/bin/ai-say "Audio test"
```
