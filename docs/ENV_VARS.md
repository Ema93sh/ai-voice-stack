# Environment Variables

## Audio Pinning

- `DICTATION_SOURCE`: Pulse/PipeWire source name for recording
  _Read by:_ `dictation-lib.sh`, `dictate-start`, `dictate-stop`, `voice-status`
- `AI_TTS_SINK`: Pulse/PipeWire sink name for playback
  _Read by:_ `ai-say`, `voice-status`

## Dictation Provider

- `DICTATION_PROVIDER` (default `faster-whisper`)
  Supported values: `faster-whisper`, `openai`, `deepgram`
  _Read by:_ `transcribe-audio`, `dictate-stop`, `voice-status`
- `DICTATION_TRANSCRIBE_BIN` (default `~/.local/bin/transcribe-audio`)
  _Read by:_ `dictate-stop`

## Dictation Behavior

- `DICTATION_AUTO_SUBMIT` (default `1`)
  Set to `0` to insert text without pressing Enter.
  _Read by:_ `dictate-stop`

## Local Dictation (faster-whisper)

- `DICTATION_LOCAL_PY` (default `~/.venvs/dictation/bin/python3`)
  _Read by:_ `transcribe-audio`
- `DICTATION_LOCAL_SCRIPT` (default `~/.local/bin/transcribe_whisper.py`)
  _Read by:_ `transcribe-audio`
- `DICTATION_MODEL` (default `small.en`)
  _Read by:_ `transcribe_whisper.py`
- `DICTATION_DEVICE` (default `cpu`)
  _Read by:_ `transcribe_whisper.py`
- `DICTATION_COMPUTE` (default `int8`)
  _Read by:_ `transcribe_whisper.py`

## OpenAI Dictation

- `OPENAI_API_KEY` (required when `DICTATION_PROVIDER=openai`)
  _Read by:_ `transcribe-audio`
- `DICTATION_OPENAI_MODEL` (default `gpt-4o-mini-transcribe`)
  _Read by:_ `transcribe-audio`
- `DICTATION_OPENAI_URL` (default `https://api.openai.com/v1/audio/transcriptions`)
  _Read by:_ `transcribe-audio`

## Deepgram Dictation

- `DEEPGRAM_API_KEY` (required when `DICTATION_PROVIDER=deepgram`)
  _Read by:_ `transcribe-audio`
- `DICTATION_DEEPGRAM_MODEL` (default `nova-3`)
  _Read by:_ `transcribe-audio`
- `DICTATION_DEEPGRAM_URL` (default `https://api.deepgram.com/v1/listen`)
  _Read by:_ `transcribe-audio`

## Dictation Timing Controls

- `DICTATION_MAX_RECORD_MS` (default `15000`)
  _Read by:_ `dictate-start`
- `DICTATION_MIN_HOLD_MS` (default `250`)
  _Read by:_ `dictate-stop`
- `DICTATION_KEYUP_DEBOUNCE_MS` (default `120`)
  _Read by:_ `dictate-stop`
- `DICTATION_TMUX_SUBMIT_DELAY_S` (default `0.12`)
  _Read by:_ `dictate-stop`

## TTS Controls (global)

- `AI_TTS_MAX_CHARS` (default `1600`)
  _Read by:_ `ai-say`
- `AI_TTS_CHUNK_CHARS` (default `320`)
  _Read by:_ `ai-say`
- `AI_TTS_VOICE` (flite fallback voice, default `slt`)
  _Read by:_ `ai-say`
- `AI_TTS_GAIN_DB` (flite fallback gain, default `16`)
  _Read by:_ `ai-say`
- `AI_TTS_TEMPO` (flite fallback tempo, default `0.9`)
  _Read by:_ `ai-say`

## Kokoro Controls

- `AI_KOKORO_PY` (default `~/.local/share/kokoro-tts/.venv/bin/python`)
  _Read by:_ `ai-say`
- `AI_KOKORO_SCRIPT` (default `~/.local/share/kokoro-tts/synthesize.py`)
  _Read by:_ `ai-say`
- `AI_KOKORO_VOICE` (default `af_bella` via config)
  _Read by:_ `ai-say`, `kokoro-synthesize.py`
- `AI_KOKORO_LANG` (default `a`)
  _Read by:_ `ai-say`, `kokoro-synthesize.py`
- `AI_KOKORO_REPO` (default `hexgrad/Kokoro-82M`)
  _Read by:_ `ai-say`, `kokoro-synthesize.py`
- `AI_KOKORO_HF_HOME` (default `~/.local/share/kokoro-tts/hf-cache`)
  _Read by:_ `ai-say`
- `AI_KOKORO_GAIN_DB` (default `16`)
  _Read by:_ `ai-say`

## Current Sample Config

See `config/ai-audio.env.sample`.
