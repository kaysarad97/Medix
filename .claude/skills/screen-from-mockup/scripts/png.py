"""Минимальный декодер PNG на стандартной библиотеке — для замеров по макетам."""

import struct
import sys
import zlib


class Png:
    def __init__(self, path):
        data = open(path, "rb").read()
        assert data[:8] == b"\x89PNG\r\n\x1a\n", "не PNG"
        pos = 8
        idat = b""
        palette = None
        trns = None
        while pos < len(data):
            (length,) = struct.unpack(">I", data[pos : pos + 4])
            ctype = data[pos + 4 : pos + 8]
            body = data[pos + 8 : pos + 8 + length]
            if ctype == b"IHDR":
                (self.w, self.h, self.depth, self.color, comp, filt, inter) = (
                    struct.unpack(">IIBBBBB", body)
                )
                assert self.depth == 8, f"глубина {self.depth} не поддержана"
                assert inter == 0, "интерлейс не поддержан"
            elif ctype == b"PLTE":
                palette = body
            elif ctype == b"tRNS":
                trns = body
            elif ctype == b"IDAT":
                idat += body
            elif ctype == b"IEND":
                break
            pos += 12 + length

        channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[self.color]
        raw = zlib.decompress(idat)
        stride = self.w * channels
        out = bytearray(self.h * stride)
        prev = bytearray(stride)
        p = 0
        for y in range(self.h):
            f = raw[p]
            p += 1
            line = bytearray(raw[p : p + stride])
            p += stride
            if f == 1:
                for i in range(channels, stride):
                    line[i] = (line[i] + line[i - channels]) & 0xFF
            elif f == 2:
                for i in range(stride):
                    line[i] = (line[i] + prev[i]) & 0xFF
            elif f == 3:
                for i in range(stride):
                    a = line[i - channels] if i >= channels else 0
                    line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xFF
            elif f == 4:
                for i in range(stride):
                    a = line[i - channels] if i >= channels else 0
                    b = prev[i]
                    c = prev[i - channels] if i >= channels else 0
                    pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                    pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                    line[i] = (line[i] + pr) & 0xFF
            out[y * stride : (y + 1) * stride] = line
            prev = line

        self._px = out
        self._ch = channels
        self._palette = palette
        self._trns = trns

    def rgb(self, x, y):
        """Цвет пикселя как (r, g, b)."""
        i = (y * self.w + x) * self._ch
        px = self._px
        if self.color == 3:
            idx = px[i]
            return tuple(self._palette[idx * 3 : idx * 3 + 3])
        if self.color in (0, 4):
            g = px[i]
            return (g, g, g)
        return (px[i], px[i + 1], px[i + 2])

    def hex(self, x, y):
        return "#%02X%02X%02X" % self.rgb(x, y)


def near(a, b, tol=6):
    return all(abs(x - y) <= tol for x, y in zip(a, b))


def row_runs(img, y, x0=0, x1=None, tol=6):
    """Горизонтальные участки одного цвета в строке y."""
    x1 = x1 if x1 is not None else img.w
    runs = []
    start = x0
    cur = img.rgb(x0, y)
    for x in range(x0 + 1, x1):
        c = img.rgb(x, y)
        if not near(c, cur, tol):
            runs.append((start, x - 1, x - start, "#%02X%02X%02X" % cur))
            start, cur = x, c
    runs.append((start, x1 - 1, x1 - start, "#%02X%02X%02X" % cur))
    return runs


def col_runs(img, x, y0=0, y1=None, tol=6):
    """Вертикальные участки одного цвета в столбце x."""
    y1 = y1 if y1 is not None else img.h
    runs = []
    start = y0
    cur = img.rgb(x, y0)
    for y in range(y0 + 1, y1):
        c = img.rgb(x, y)
        if not near(c, cur, tol):
            runs.append((start, y - 1, y - start, "#%02X%02X%02X" % cur))
            start, cur = y, c
    runs.append((start, y1 - 1, y1 - start, "#%02X%02X%02X" % cur))
    return runs


if __name__ == "__main__":
    img = Png(sys.argv[1])
    print(f"{img.w}x{img.h} color={img.color}")
