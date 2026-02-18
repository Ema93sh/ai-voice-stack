# Key Decisions and Why

## Dictation

1. Hold-to-record key: Menu key via xbindkeys using keycode-only bindings `c:135` and fallback `c:147`.
2. Input capture: `ffmpeg -f pulse` to WAV at 16k mono.
3. Transcription: `faster-whisper` (`small.en`, CPU/int8 defaults).
4. Insertion path priority:
   - tmux paste-buffer
   - Wayland clipboard + ydotool
   - X11 xdotool type
5. Safety and stability:
   - file lock around start/stop
   - auto-stop timeout
   - minimum hold threshold
   - repeat-keyup debounce

## TTS

1. Primary engine: Kokoro (`hexgrad/Kokoro-82M`) via local Python script.
2. Playback: `paplay` to pinned sink.
3. Loudness handling: ffmpeg gain + limiter before playback.
4. Fallbacks:
   - ffmpeg `flite`
   - speech-dispatcher (`spd-say`)

## Why this stack

- Fully local operation.
- Robust in tmux-heavy workflows.
- Works with pinned audio devices and mixed sink/source setups.
- Quality significantly better than pure flite path.
