"""Границы содержимого внутри прямоугольника — для снятия координат текста."""

from png import Png, near


def ink_lines(img, x0, y0, x1, y1, bg, tol=14, gap=3):
    """Разбивает область на строки содержимого и даёт их bbox.

    bg — цвет подложки; всё, что от него отличается больше чем на tol,
    считается содержимым. gap — сколько пустых строк разрывают блок.
    """
    rows = []
    for y in range(y0, y1):
        xs = [x for x in range(x0, x1) if not near(img.rgb(x, y), bg, tol)]
        rows.append((y, xs))

    lines = []
    cur = None
    empty = 0
    for y, xs in rows:
        if xs:
            if cur is None:
                cur = {"y0": y, "y1": y, "x0": min(xs), "x1": max(xs)}
            else:
                cur["y1"] = y
                cur["x0"] = min(cur["x0"], min(xs))
                cur["x1"] = max(cur["x1"], max(xs))
            empty = 0
        elif cur is not None:
            empty += 1
            if empty > gap:
                lines.append(cur)
                cur = None
    if cur is not None:
        lines.append(cur)
    return lines


def report(img, x0, y0, x1, y1, bg, label, tol=14, gap=3):
    print(f"--- {label}  (подложка {bg})")
    for ln in ink_lines(img, x0, y0, x1, y1, bg, tol, gap):
        w = ln["x1"] - ln["x0"] + 1
        h = ln["y1"] - ln["y0"] + 1
        print(
            f"    x {ln['x0']}…{ln['x1']} (ш {w})   "
            f"y {ln['y0']}…{ln['y1']} (в {h})"
        )


def edges(img, axis, fixed, start, end, bg, tol=14):
    """Первая и последняя координата, отличная от bg, вдоль оси."""
    hit = []
    for v in range(start, end):
        c = img.rgb(v, fixed) if axis == "x" else img.rgb(fixed, v)
        if not near(c, bg, tol):
            hit.append(v)
    return (hit[0], hit[-1]) if hit else None
