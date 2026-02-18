# Usage

## Push-to-Talk Dictation

- Press and hold Menu key.
- Binding uses keycode-only mapping (`c:135`) with fallback (`c:147`) to avoid Mod2/NumLock issues.
- Speak.
- Release Menu key.
- Transcribed text is inserted at cursor (tmux-aware).
- Script then sends Enter/Ctrl+Enter based on context.

## Dictation Provider Switch

Local (default):

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

Apply changes:

```bash
source ~/.config/ai-audio.env
```

## TTS

Default:

```bash
~/.local/bin/ai-say "Hello"
```

Temporary voice switch:

```bash
AI_KOKORO_VOICE=af_nova ~/.local/bin/ai-say "Testing"
```

Speak last tmux assistant block:

```bash
~/.local/bin/ai-tts-last
```

## Hotkey Service

```bash
~/.local/bin/dictation-hotkeys
```

This command:
- disables repeat attempts for keycodes `135` and `147`
- restarts xbindkeys with `~/.xbindkeysrc`
