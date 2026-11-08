#!/usr/bin/env python3
"""Gera os efeitos sonoros do jogo (audio/sfx/*.wav) por síntese, sem arquivos de terceiros.
Rodar: python3 tools/gen_sounds.py  (só usa a biblioteca padrão do Python)."""
import math
import os
import random
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio", "sfx")


def env(i, n, attack=0.005, release=0.6):
    t = i / RATE
    dur = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = max(0.0, 1.0 - (t / dur)) ** (1.0 / max(release, 0.01))
    return a * r


def tone(freqs, dur, vol=0.5, attack=0.005, release=0.6, wave_kind="sine", glide=0.0):
    n = int(RATE * dur)
    out = []
    phase = [0.0] * len(freqs)
    for i in range(n):
        s = 0.0
        k = i / n
        for j, f in enumerate(freqs):
            f2 = f * (1.0 + glide * k)
            phase[j] += 2 * math.pi * f2 / RATE
            if wave_kind == "sine":
                s += math.sin(phase[j])
            else:  # "soft": seno com um pouco de harmônico (som de bolha/vidro)
                s += math.sin(phase[j]) + 0.25 * math.sin(2 * phase[j]) + 0.1 * math.sin(3 * phase[j])
        out.append(vol * env(i, n, attack, release) * s / len(freqs))
    return out


def concat(*parts, gap=0.0):
    out = []
    for p in parts:
        out.extend(p)
        out.extend([0.0] * int(RATE * gap))
    return out


def mix(a, b, offset=0.0):
    start = int(RATE * offset)
    n = max(len(a), start + len(b))
    out = [0.0] * n
    for i, v in enumerate(a):
        out[i] += v
    for i, v in enumerate(b):
        out[start + i] += v
    return out


def pour(dur=0.45):
    """Líquido escorrendo: bolhinhas com tom subindo (a garrafa enchendo)."""
    random.seed(7)
    out = [0.0] * int(RATE * dur)
    t = 0.0
    while t < dur - 0.05:
        f = 380 + 520 * (t / dur) + random.uniform(-40, 40)
        b = tone([f], random.uniform(0.04, 0.07), vol=random.uniform(0.18, 0.3), attack=0.003, release=0.35, glide=0.6)
        out = mix(out, b, t)
        t += random.uniform(0.018, 0.035)
    return out


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(v) for v in samples))
    scale = 0.85 / peak if peak > 0.85 else 1.0
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32767)) for v in samples))


save("tap", tone([880, 1320], 0.08, vol=0.45, release=0.4, wave_kind="soft"))
save("click", tone([660], 0.06, vol=0.4, release=0.35, wave_kind="soft"))
save("pour", pour())
save("wrong", concat(tone([220], 0.09, vol=0.45, release=0.5, wave_kind="soft"), tone([185], 0.12, vol=0.45, release=0.5, wave_kind="soft")))
save("bottle_done", concat(tone([784], 0.07, vol=0.4), tone([1046], 0.07, vol=0.4), tone([1318], 0.16, vol=0.45, release=0.8)))
save("win", concat(
    tone([523, 659], 0.11, vol=0.45), tone([659, 784], 0.11, vol=0.45), tone([784, 988], 0.11, vol=0.45),
    tone([1046, 1318, 1568], 0.45, vol=0.5, release=1.2)))
save("lose", concat(tone([392], 0.16, vol=0.4, wave_kind="soft"), tone([330], 0.16, vol=0.4, wave_kind="soft"), tone([262], 0.35, vol=0.4, release=1.0, wave_kind="soft")))
print("sons gerados em", os.path.normpath(OUT))
