#!/usr/bin/env python3
import argparse
import os
import sys

import numpy as np
import soundfile as sf
from kokoro import KPipeline


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Synthesize speech with Kokoro")
    p.add_argument("--text", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--voice", default="af_heart")
    p.add_argument("--lang", default="a")
    p.add_argument("--repo", default="hexgrad/Kokoro-82M")
    p.add_argument("--sample-rate", type=int, default=24000)
    return p.parse_args()


def main() -> int:
    args = parse_args()
    text = args.text.strip()
    if not text:
        return 0

    os.environ.setdefault("CUDA_VISIBLE_DEVICES", "")

    pipeline = KPipeline(lang_code=args.lang, repo_id=args.repo)
    parts = []
    for _, _, audio in pipeline(text, voice=args.voice):
        if audio is not None:
            parts.append(np.asarray(audio, dtype=np.float32))

    if not parts:
        return 2

    audio = np.concatenate(parts)
    sf.write(args.out, audio, args.sample_rate)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
