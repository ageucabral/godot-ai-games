#!/usr/bin/env python3
"""Gera as duas músicas de fundo do jogo por síntese, sem arquivos de terceiros:
- audio/music/calm.ogg (menus): caixinha de música calma (arpejos) sobre acordes suaves;
- audio/music/play.ogg (partida): marimba leve e um pouco mais animada, para pensar sem cansar.
Cada uma tem 8 compassos que se repetem sem emenda.
Rodar: python3 tools/gen_music.py  (precisa do ffmpeg para converter o WAV em OGG)."""
import math
import os
import struct
import subprocess
import tempfile
import wave

RATE = 22050
MUSIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio", "music")

# Cada música: andamento, acordes (notas MIDI, um por compasso de 4 tempos), desenho do arpejo em colcheias
# (índice da nota do acorde; +3 = uma oitava acima) e o timbre da melodia.
TRACKS = {
    # C, Am, F, G, C, Em, F, G
    "calm": (84, [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62], [60, 64, 67], [52, 55, 59], [53, 57, 60], [55, 59, 62]],
             [0, 1, 2, 4, 3, 2, 1, 2], "bell"),
    # F, Dm, Bb, C, F, Am, Bb, C (um tom acima, mais leve)
    "play": (96, [[65, 69, 72], [62, 65, 69], [58, 62, 65], [60, 64, 67], [65, 69, 72], [57, 60, 64], [58, 62, 65], [60, 64, 67]],
             [0, 2, 1, 3, 2, 4, 3, 1], "marimba"),
}


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def render(name, bpm, chords, arp, lead):
    beat = 60.0 / bpm
    total = int(RATE * beat * 4 * len(chords))
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
            elif kind == "marimba":  # madeira: ataque curto, some rápido, harmônico 4x
                env = min(1.0, t / 0.003) * math.exp(-t * 6.5)
                s = math.sin(2 * math.pi * f * t) + 0.25 * math.sin(2 * math.pi * f * 4 * t) * math.exp(-t * 18)
            else:  # acorde de fundo: entra e sai devagar
                env = math.sin(math.pi * min(1.0, t / dur_s)) ** 1.5
                s = math.sin(2 * math.pi * f * t) + 0.15 * math.sin(2 * math.pi * f * 2 * t)
            # dá a volta no fim: a música repete sem emenda
            buf[(n0 + i) % total] += vol * env * s

    for bar, chord in enumerate(chords):
        start = bar * 4 * beat
        for m in chord:
            add_note(start, m - 12 - (12 if lead == "marimba" else 0), 4 * beat, 0.06, "pad")
        for k, idx in enumerate(arp):
            midi = chord[idx % 3] + 12 * (1 + idx // 3) - (12 if lead == "marimba" else 0)
            add_note(start + k * beat / 2, midi, beat * (1.2 if lead == "marimba" else 2.5), 0.11, lead)

    out = os.path.join(MUSIC_DIR, name + ".ogg")
    peak = max(abs(x) for x in buf) or 1.0
    os.makedirs(MUSIC_DIR, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, name + ".wav")
        with wave.open(wav_path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", int(32767 * 0.8 * x / peak)) for x in buf))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "3", out], check=True)
    print("ok", out)


def main():
    for name, (bpm, chords, arp, lead) in TRACKS.items():
        render(name, bpm, chords, arp, lead)


if __name__ == "__main__":
    main()
