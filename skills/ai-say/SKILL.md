---
name: ai-say
description: >-
  Local text-to-speech on Ubuntu using Kokoro TTS with fallbacks.
  Use when the user asks to speak text out loud, test audio output,
  switch Kokoro voices, or debug TTS playback issues.
  Triggers on "say this", "read aloud", "speak", "TTS", "voice test".
license: MIT
metadata:
  author: Ema93sh
  version: "1.0.0"
---

# AI Say

Local text-to-speech via `~/.local/bin/ai-say`. Kokoro-first with flite and
speech-dispatcher fallbacks. Requires the voice stack to be installed first.

## Prerequisites

The voice stack must be installed before using this skill:

```bash
git clone https://github.com/Ema93sh/ai-voice-stack.git
cd ai-voice-stack
scripts/voice-up-setup.sh --with-system-deps
```

This installs `ai-say` to `~/.local/bin/` and sets up Kokoro TTS.

## Usage

Speak text:

```bash
~/.local/bin/ai-say "Hello world"
```

Pipe text:

```bash
echo "Read this aloud" | ~/.local/bin/ai-say
```

Temporary voice override:

```bash
AI_KOKORO_VOICE=am_michael ~/.local/bin/ai-say "Different voice"
```

## Available Voices

### English (American)

**Female:** `af_alloy`, `af_aoede`, `af_bella`, `af_heart` (default), `af_jessica`,
`af_kore`, `af_nicole`, `af_nova`, `af_river`, `af_sarah`, `af_sky`

**Male:** `am_adam`, `am_echo`, `am_eric`, `am_fenrir`, `am_liam`,
`am_michael`, `am_onyx`, `am_puck`, `am_santa`

### English (British)

**Female:** `bf_alice`, `bf_emma`, `bf_isabella`, `bf_lily`

**Male:** `bm_daniel`, `bm_fable`, `bm_george`, `bm_lewis`

### Other Languages

Spanish (`ef_dora`, `em_alex`), French (`ff_siwis`), Hindi (`hf_alpha`,
`hf_beta`, `hm_omega`, `hm_psi`), Italian (`if_sara`, `im_nicola`),
Japanese (`jf_alpha`, `jf_gongitsune`, `jf_nezumi`, `jf_tebukuro`, `jm_kumo`),
Portuguese (`pf_dora`, `pm_alex`), Chinese (`zf_xiaobei`, `zf_xiaoni`,
`zf_xiaoxiao`, `zf_xiaoyi`, `zm_yunjian`, `zm_yunxi`, `zm_yunxia`, `zm_yunyang`)

## Persistent Voice Change

Edit `~/.config/ai-audio.env`:

```bash
export AI_KOKORO_VOICE="${AI_KOKORO_VOICE:-af_bella}"
```

## Volume / Gain

If speech is too quiet:

```bash
export AI_KOKORO_GAIN_DB=18
~/.local/bin/ai-say "Volume test"
```

## Diagnostics

Check stack health:

```bash
~/.local/bin/voice-status
```

Check audio devices:

```bash
pactl list short sinks
pactl list short sources
cat ~/.config/ai-audio.env
```

Test direct tone on a specific sink:

```bash
ffmpeg -hide_banner -loglevel error -f lavfi -i 'sine=frequency=880:duration=3' -f wav - | paplay --device='<sink-name>'
```

## Notes

- `ai-say` is Kokoro-first, with flite and spd-say fallback paths.
- Text is truncated at 1600 chars and chunked at 320 chars for reliable playback.
- Keep messages respectful and follow user intent exactly for spoken content.
