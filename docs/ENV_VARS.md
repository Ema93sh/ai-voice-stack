# Environment Variables

## Audio Pinning

- `DICTATION_SOURCE`: Pulse/PipeWire source name for recording
- `AI_TTS_SINK`: Pulse/PipeWire sink name for playback

## Dictation Provider

- `DICTATION_PROVIDER` (default `faster-whisper`)
- Supported values: `faster-whisper`, `openai`, `deepgram`
- `DICTATION_TRANSCRIBE_BIN` (default `~/.local/bin/transcribe-audio`)

## Local Dictation (faster-whisper)

- `DICTATION_LOCAL_PY` (default `~/.venvs/dictation/bin/python3`)
- `DICTATION_LOCAL_SCRIPT` (default `~/.local/bin/transcribe_whisper.py`)
- `DICTATION_MODEL` (default `small.en`)
- `DICTATION_DEVICE` (default `cpu`)
- `DICTATION_COMPUTE` (default `int8`)

## OpenAI Dictation

- `OPENAI_API_KEY` (required when `DICTATION_PROVIDER=openai`)
- `DICTATION_OPENAI_MODEL` (default `gpt-4o-mini-transcribe`)
- `DICTATION_OPENAI_URL` (default `https://api.openai.com/v1/audio/transcriptions`)

## Deepgram Dictation

- `DEEPGRAM_API_KEY` (required when `DICTATION_PROVIDER=deepgram`)
- `DICTATION_DEEPGRAM_MODEL` (default `nova-3`)
- `DICTATION_DEEPGRAM_URL` (default `https://api.deepgram.com/v1/listen`)

## Dictation Timing Controls

- `DICTATION_MAX_RECORD_MS` (default `15000`)
- `DICTATION_MIN_HOLD_MS` (default `250`)
- `DICTATION_KEYUP_DEBOUNCE_MS` (default `120`)
- `DICTATION_TMUX_SUBMIT_DELAY_S` (default `0.12`)

## TTS Controls (global)

- `AI_TTS_MAX_CHARS` (default `1600`)
- `AI_TTS_CHUNK_CHARS` (default `320`)
- `AI_TTS_VOICE` (flite fallback voice, default `slt`)
- `AI_TTS_GAIN_DB` (flite fallback gain, default `16`)
- `AI_TTS_TEMPO` (flite fallback tempo, default `0.9`)

## Kokoro Controls

- `AI_KOKORO_PY` (default `~/.local/share/kokoro-tts/.venv/bin/python`)
- `AI_KOKORO_SCRIPT` (default `~/.local/share/kokoro-tts/synthesize.py`)
- `AI_KOKORO_VOICE` (default `af_bella` via config)
- `AI_KOKORO_LANG` (default `a`)
- `AI_KOKORO_REPO` (default `hexgrad/Kokoro-82M`)
- `AI_KOKORO_HF_HOME` (default `~/.local/share/kokoro-tts/hf-cache`)
- `AI_KOKORO_GAIN_DB` (default `16`)

## Current Sample Config

See `config/ai-audio.env.sample`.
