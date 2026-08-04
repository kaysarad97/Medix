"""Вырезает область макета в отдельный PNG — для визуальной проверки."""

import struct
import sys
import zlib

from png import Png


def write_png(path, w, h, get_rgb, scale=1):
    rows = []
    for y in range(h):
        line = bytearray([0])
        for x in range(w):
            r, g, b = get_rgb(x, y)
            line += bytes((r, g, b)) * scale
        for _ in range(scale):
            rows.append(bytes(line))
    raw = b"".join(rows)

    def chunk(tag, body):
        return (
            struct.pack(">I", len(body))
            + tag
            + body
            + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
        )

    out = b"\x89PNG\r\n\x1a\n"
    out += chunk(b"IHDR", struct.pack(">IIBBBBB", w * scale, h * scale, 8, 2, 0, 0, 0))
    out += chunk(b"IDAT", zlib.compress(raw, 6))
    out += chunk(b"IEND", b"")
    open(path, "wb").write(out)


if __name__ == "__main__":
    src, dst, x0, y0, x1, y1 = sys.argv[1:7]
    scale = int(sys.argv[7]) if len(sys.argv) > 7 else 1
    img = Png(src)
    x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
    write_png(dst, x1 - x0, y1 - y0, lambda x, y: img.rgb(x0 + x, y0 + y), scale)
    print(f"{dst}: {(x1 - x0) * scale}x{(y1 - y0) * scale}")
