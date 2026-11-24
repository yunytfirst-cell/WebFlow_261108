"""Flow 앱 아이콘(windows/runner/resources/app_icon.ico) 생성.

2026-11-24 사용자 지시: "실행파일 아이콘이 너무 작아서 안 보인다, 노란색 아이콘처럼 크고 잘 보이게".
- 바탕: 캔버스를 거의 꽉 채우는 노란 둥근 사각형 (예전: 어두운 남색 바탕 + 얇은 노란 링이라 작게 보면 안 보였음)
- 그림: 진한 남색 굵은 링(오른쪽 위가 열림) + 굵은 위쪽 화살표
- 크기별로 4배 크게 그린 뒤 줄여서 선명하게 만든다. 16·24px은 링을 빼고 화살표만 더 굵게 그린다.
실행: python tools/make_icon.py  (만든 뒤 python tools/build_exe.py 로 exe에 반영)
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
PREVIEW = ROOT / "tools" / "app_icon_preview.png"

YELLOW_TOP = (255, 214, 10)
YELLOW_BOTTOM = (255, 170, 0)
NAVY = (20, 28, 58)
SIZES = [256, 128, 64, 48, 32, 24, 16]


def draw_icon(size: int) -> Image.Image:
    s = size * 4  # 크게 그린 뒤 줄여 계단 현상 제거
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    # 노란 세로 그라데이션 바탕을 둥근 사각형 모양으로 자른다
    grad = Image.new("RGBA", (s, s))
    gd = ImageDraw.Draw(grad)
    for y in range(s):
        t = y / (s - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(YELLOW_TOP, YELLOW_BOTTOM))
        gd.line([(0, y), (s, y)], fill=c + (255,))
    mask = Image.new("L", (s, s), 0)
    margin = round(s * 0.01)  # 참고 아이콘(노란 메모)처럼 칸을 거의 꽉 채운다
    ImageDraw.Draw(mask).rounded_rectangle(
        [margin, margin, s - margin, s - margin], radius=round(s * 0.12), fill=255
    )
    img.paste(grad, (0, 0), mask)

    d = ImageDraw.Draw(img)
    small = size <= 24
    cx = cy = s / 2

    if not small:
        # 굵은 링 (오른쪽 위 열림)
        r = s * 0.34
        w = round(s * 0.10)
        d.arc([cx - r, cy - r, cx + r, cy + r], start=-50, end=250, fill=NAVY, width=w)

    # 굵은 위쪽 화살표
    shaft_w = s * (0.20 if small else 0.13)
    head_w = s * (0.62 if small else 0.40)
    top = s * (0.14 if small else 0.22)
    head_h = s * (0.34 if small else 0.24)
    bottom = s * (0.86 if small else 0.74)
    d.polygon(
        [(cx, top), (cx + head_w / 2, top + head_h), (cx - head_w / 2, top + head_h)],
        fill=NAVY,
    )
    # 기둥: 위는 화살촉에 붙게 평평하게, 아래만 둥글게
    d.rectangle([cx - shaft_w / 2, top + head_h - 2, cx + shaft_w / 2, bottom - shaft_w / 2], fill=NAVY)
    d.ellipse([cx - shaft_w / 2, bottom - shaft_w, cx + shaft_w / 2, bottom], fill=NAVY)
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    images = [draw_icon(n) for n in SIZES]
    images[0].save(OUT, format="ICO", sizes=[(n, n) for n in SIZES], append_images=images[1:])
    # 미리보기: 크기별로 나란히
    sheet = Image.new("RGBA", (sum(SIZES) + 10 * len(SIZES), 256), (40, 40, 40, 255))
    x = 0
    for im in images:
        sheet.paste(im, (x, 256 - im.height), im)
        x += im.width + 10
    sheet.save(PREVIEW)
    print(f"아이콘 저장: {OUT}")
    print(f"미리보기: {PREVIEW}")


if __name__ == "__main__":
    main()
