#!/usr/bin/env python3
"""Gera assets/fonts/NotoColorEmoji-subset.ttf: só os emojis que aparecem nos scripts do jogo (scripts/), tirados do
Noto Color Emoji (licença SIL OFL 1.1). O Godot usa essa letra como reserva das outras duas para desenhar os ícones
coloridos (sequência, conquistas, configurações...).
Rodar depois de usar um emoji novo: python3 tools/gen_emoji_font.py  (precisa do fonttools e do Noto Color Emoji:
apt install fonts-noto-color-emoji; pip install fonttools). Depois: tools/godot.sh --headless --path . --import"""
import os
import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"
OUT = ROOT / "assets" / "fonts" / "NotoColorEmoji-subset.ttf"


def is_emoji(ch: str) -> bool:
    cp = ord(ch)
    return cp >= 0x2190 and not (0x2500 <= cp <= 0x25FF and cp not in (0x25B6, 0x25C0)) and cp not in (0x2026, 0x2014, 0x2013)


def main() -> None:
    chars = set()
    for path in (ROOT / "scripts").rglob("*.gd"):
        chars.update(ch for ch in path.read_text(encoding="utf-8") if is_emoji(ch))
    font = TTFont(SOURCE)
    cmap = font.getBestCmap()
    chars = {ch for ch in chars if ord(ch) in cmap}
    opts = subset.Options()
    opts.layout_features = ["*"]
    sub = subset.Subsetter(opts)
    sub.populate(text="".join(sorted(chars)) + "️‍")
    sub.subset(font)
    font.save(OUT)
    print(f"ok {OUT} ({len(chars)} emojis, {os.path.getsize(OUT) // 1024} KB)")


if __name__ == "__main__":
    sys.exit(main())
