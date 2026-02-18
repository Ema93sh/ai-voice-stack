# Troubleshooting

## 1) Push-to-talk is stuck or random-triggering

Symptoms:
- recorder keeps running
- repeated start/stop loop while key held

Checks:

```bash
ps -ef | rg 'dictate-start|dictate-stop|ffmpeg -nostdin -loglevel error -f pulse -i'
tail -n 100 ${XDG_RUNTIME_DIR:-/run/user/1000}/dictation/dictation.log
```

Fix:

```bash
pkill -f 'dictate-start|dictate-stop|ffmpeg -nostdin -loglevel error -f pulse -i' || true
rm -f ${XDG_RUNTIME_DIR:-/run/user/1000}/dictation/rec.pid \
      ${XDG_RUNTIME_DIR:-/run/user/1000}/dictation/start_ms \
      ${XDG_RUNTIME_DIR:-/run/user/1000}/dictation/last_down_ms
~/.local/bin/dictation-hotkeys
```

Tune debounce:

```bash
export DICTATION_KEYUP_DEBOUNCE_MS=180
```

Ensure your `~/.xbindkeysrc` uses keycode-only bindings (no `m:0x10`/Mod2):

```bash
"/home/ema93sh/.local/bin/dictate-start"
  c:135
"/home/ema93sh/.local/bin/dictate-stop"
  release + c:135
"/home/ema93sh/.local/bin/dictate-start"
  c:147
"/home/ema93sh/.local/bin/dictate-stop"
  release + c:147
```

## 2) "No speech detected"

- Confirm mic source:

```bash
pactl list short sources
pactl info | rg 'Default Source'
```

- Confirm pinned source in `~/.config/ai-audio.env`.
- Check mic mute/volume in system settings.

## 3) TTS plays but too quiet

Kokoro output may be low RMS. Increase:

```bash
export AI_KOKORO_GAIN_DB=18
```

## 4) Voice override ignored

Config should use fallback expansion:

```bash
export AI_KOKORO_VOICE="${AI_KOKORO_VOICE:-af_bella}"
```

Then inline override works:

```bash
AI_KOKORO_VOICE=am_michael ~/.local/bin/ai-say "voice test"
```

## 5) tmux paste works but Enter does not submit

Current behavior:
- tmux: sends Enter to pane (`send-keys Enter`)
- non-tmux: sends Ctrl+Enter on X11/Wayland path

If app-specific submit differs, customize `press_enter` in `scripts/dictate-stop`.

## 6) Device inventory

```bash
pactl list short sinks
pactl list short sources
pactl info | rg 'Default Sink|Default Source'
```
