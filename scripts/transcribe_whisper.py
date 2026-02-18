#!/usr/bin/env python3
import os
import sys

from faster_whisper import WhisperModel

if len(sys.argv) < 2:
    raise SystemExit("usage: transcribe_whisper.py <audio-file>")

audio = sys.argv[1]
model_name = os.environ.get("DICTATION_MODEL", "small.en")
device = os.environ.get("DICTATION_DEVICE", "cpu")
compute = os.environ.get("DICTATION_COMPUTE", "int8")

model = WhisperModel(model_name, device=device, compute_type=compute)
segments, _ = model.transcribe(audio, vad_filter=True, beam_size=1)
text = " ".join(s.text.strip() for s in segments).strip()
print(text, end="")
