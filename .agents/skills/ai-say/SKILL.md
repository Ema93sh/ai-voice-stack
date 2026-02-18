---
name: ai-say
description: Use local ai-say text-to-speech in ai-voice-stack when the user asks to speak text out loud, test audio output, switch Kokoro voices, or debug ai-say playback issues on Ubuntu.
---

# AI Say

Use this skill to run local speech output through `~/.local/bin/ai-say`.

## Run Speech

Use this for normal playback:

```bash
~/.local/bin/ai-say "<text>"
```

If running in a sandboxed agent session, request escalated execution when needed so `ai-say` can access user runtime audio state and play through the real sink.

## Voice Selection

Temporary voice for one command:

```bash
AI_KOKORO_VOICE=am_michael ~/.local/bin/ai-say "<text>"
```

Persistent default voice is controlled in `~/.config/ai-audio.env`:

```bash
export AI_KOKORO_VOICE="${AI_KOKORO_VOICE:-af_bella}"
```

Reference available voices in `docs/VOICES.md`.

## Common Tasks

Play a short test line:

```bash
~/.local/bin/ai-say "Audio test"
```

Play a longer message:

```bash
~/.local/bin/ai-say "<long text>"
```

## Quick Debug Flow (No Audio)

1. Verify configured sink and source:

```bash
cat ~/.config/ai-audio.env
pactl list short sinks
pactl list short sources
pactl info | rg 'Default Sink|Default Source'
```

2. Test direct tone on sink:

```bash
ffmpeg -hide_banner -loglevel error -f lavfi -i 'sine=frequency=880:duration=3' -f wav - | paplay --device='<sink-name>'
```

3. Increase Kokoro gain if speech is too quiet:

```bash
export AI_KOKORO_GAIN_DB=18
~/.local/bin/ai-say "Volume test"
```

## Install

```bash
npx skills add Ema93sh/ai-voice-stack
```

## Notes

- `ai-say` is Kokoro-first, with fallback paths.
- Keep messages respectful and follow user intent exactly for spoken content.
