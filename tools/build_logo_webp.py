#!/usr/bin/env python3
"""Анимация логотипа для заставки — из кадров дизайнера, а не из вектора.

Зачем именно кадры. Дизайнер отдал движение покадрово: `icons/BlueLogo.json` —
это Lottie, внутри которого 103 растровых слоя, по картинке на кадр. Кисть в
нём идёт по осевой линии штрихов и стирается позади себя. Повторить это
вектором мы пробовали дважды — обводкой силуэта из `logo_medix.svg` и
восстановлением траектории по кадрам, — и оба раза заказчик сказал, что
движение не то. Приближение тут не проходит: сверяют с оригиналом.

Почему исходники не годились как есть. Гифка на 378 КБ не проигрывалась:
96 кадров 625×625 распаковывались медленнее собственных задержек, и знак
замирал на первых штрихах. Сам `BlueLogo.json` ещё тяжелее — 1,25 МБ.

Что делает скрипт: берёт кадры из `BlueLogo.json`, перекрашивает в белый
(в макетах знак белый, а у дизайнера синий), ужимает с 625 до 288 — это
ровно размер показа, 96 точек при трёхкратной плотности, — и складывает в
анимированный WebP. Пикселей на кадр становится впятеро меньше, и причина
торможения уходит. WebP, а не GIF: у GIF прозрачность однобитная, и края
знака вышли бы рваными.

Нужны numpy и Pillow — в зависимостях приложения их нет, это отдельный
инструмент:

    python3 -m venv venv && ./venv/bin/pip install pillow
    ./venv/bin/python tools/build_logo_webp.py
"""

from __future__ import annotations

import argparse
import base64
import io
import json
from pathlib import Path

from PIL import Image, ImageSequence

# Размер показа: `MedixWaitView.animationSize` равен 96 точкам, дальше
# трёхкратная плотность экрана.
SIZE = 288

# Кадр при 30 к/с. WebP хранит длительность целыми миллисекундами.
FRAME_MS = 33


def frames(source: Path) -> list[Image.Image]:
    """Кадры из Lottie дизайнера, перекрашенные в белый."""
    doc = json.loads(source.read_text(encoding="utf-8"))
    out = []
    for asset in doc["assets"]:
        raw = base64.b64decode(asset["p"].split(",", 1)[1])
        image = Image.open(io.BytesIO(raw)).convert("RGBA")
        # Знак сплошного цвета на прозрачном фоне: меняем цвет, прозрачность
        # оставляем как есть — она и держит сглаженные края.
        alpha = image.getchannel("A")
        opaque = alpha.point(lambda _: 255)
        white = Image.merge("RGBA", (opaque, opaque, opaque, alpha))
        out.append(white.resize((SIZE, SIZE), Image.LANCZOS))
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default="icons/BlueLogo.json")
    parser.add_argument("--out", default="assets/images/logo_animated.webp")
    args = parser.parse_args()

    images = frames(Path(args.source))

    # Хвост пустых кадров сжимаем в один с длинной выдержкой. Иначе libwebp
    # выбрасывает одинаковые кадры вместе с их временем, и пауза перед
    # повтором — а на экранах ожидания анимация крутится по кругу — пропадает.
    tail = 0
    while tail + 1 < len(images) and not images[-1 - tail].getchannel("A").getbbox():
        tail += 1
    images = images[: len(images) - tail] + images[-1:]
    durations = [FRAME_MS] * (len(images) - 1) + [max(FRAME_MS, tail * FRAME_MS)]

    target = Path(args.out)
    images[0].save(
        target,
        format="WEBP",
        save_all=True,
        append_images=images[1:],
        duration=durations,
        # Бесконечно: на заставке уходим раньше конца, а на экранах ожидания
        # оплаты ждать можно сколько угодно, и остановка выглядела бы зависанием.
        loop=0,
        lossless=True,
        quality=80,
    )

    # Проверяем по записанному файлу, а не по тому, что собирались записать:
    # кодировщик волен склеивать кадры, и терять на этом время.
    written = Image.open(target)
    elapsed, ink_until = 0, 0
    for frame in ImageSequence.Iterator(written):
        if frame.convert("RGBA").getchannel("A").getbbox():
            ink_until = elapsed + frame.info.get("duration", 0)
        elapsed += frame.info.get("duration", 0)
    print(f"{target}: {target.stat().st_size / 1024:.0f} КБ, {SIZE}×{SIZE}")
    print(f"кадров {written.n_frames}, вся анимация {elapsed} мс, "
          f"зациклено: {written.info.get('loop') == 0}")
    print(f"след сходит на нет к {ink_until} мс — это MedixWaitView.inkGone")


if __name__ == "__main__":
    main()
