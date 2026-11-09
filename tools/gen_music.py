#!/usr/bin/env python3
"""Gera a música de fundo do jogo (audio/music/calm.ogg) por síntese, sem arquivos de terceiros.
Uma caixinha de música calma (arpejos) sobre acordes suaves, 8 compassos que se repetem sem emenda.
Rodar: python3 tools/gen_music.py  (precisa do ffmpeg para converter o WAV em OGG)."""
import math
import os
import struct
import subprocess
import tempfile
import wave

RATE = 22050
BPM = 84
BEAT = 60.0 / BPM
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio", "music", "calm.ogg")

# acordes (notas MIDI), um por compasso de 4 tempos: C, Am, F, G, C, Em, F, G
CHORDS = [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62], [60, 64, 67], [52, 55, 59], [53, 57, 60], [55, 59, 62]]
# desenho do arpejo em colcheias (índice da nota do acorde; +3 = uma oitava acima)
ARP = [0, 1, 2, 4, 3, 2, 1, 2]


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def main():
    total = int(RATE * BEAT * 4 * len(CHORDS))
    buf = [0.0] * total

    def add_note(start_s, midi, dur_s, vol, kind):
        f = freq(midi)
        n0 = int(start_s * RATE)
        n = int(dur_s * RATE)
        for i in range(n):
            t = i / RATE
            if kind == "bell":  # caixinha de música: ataque rápido e cauda longa
                env = min(1.0, t / 0.004) * math.exp(-t * 3.2)
                s = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2 * t) * math.exp(-t * 6)
            else:  # acorde de fundo: entra e sai devagar
                env = math.sin(math.pi * min(1.0, t / dur_s)) ** 1.5
                s = math.sin(2 * math.pi * f * t) + 0.15 * math.sin(2 * math.pi * f * 2 * t)
            # dá a volta no fim: a música repete sem emenda
            buf[(n0 + i) % total] += vol * env * s

    for bar, chord in enumerate(CHORDS):
        start = bar * 4 * BEAT
        for m in chord:
            add_note(start, m - 12, 4 * BEAT, 0.06, "pad")
        for k, idx in enumerate(ARP):
            midi = chord[idx % 3] + 12 * (1 + idx // 3)
            add_note(start + k * BEAT / 2, midi, BEAT * 2.5, 0.11, "bell")

    peak = max(abs(x) for x in buf) or 1.0
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "calm.wav")
        with wave.open(wav_path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", int(32767 * 0.8 * x / peak)) for x in buf))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "3", OUT], check=True)
    print("ok", OUT)


if __name__ == "__main__":
    main()
