"""리팩터링 전후 화면 스냅샷(PNG)을 픽셀 단위로 비교한다.

사용: python tools/compare_snapshots.py build/identity_before build/identity_after
같으면 "모두 같음", 다르면 파일별 다른 픽셀 수와 차이 그림(<after>/diff_<이름>.png)을 남기고 종료 코드 1.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops


def main() -> int:
    before, after = Path(sys.argv[1]), Path(sys.argv[2])
    names = sorted(p.name for p in before.glob('*.png'))
    if not names:
        print('비교할 PNG가 없습니다:', before)
        return 1
    bad = 0
    for name in names:
        a = Image.open(before / name).convert('RGBA')
        b_path = after / name
        if not b_path.exists():
            print(f'{name}: 바뀐 뒤 그림 없음')
            bad += 1
            continue
        b = Image.open(b_path).convert('RGBA')
        if a.size != b.size:
            print(f'{name}: 크기 다름 {a.size} vs {b.size}')
            bad += 1
            continue
        diff = ImageChops.difference(a, b)
        count = sum(1 for px in diff.getdata() if px != (0, 0, 0, 0))
        if count:
            print(f'{name}: 다른 픽셀 {count}개')
            diff.point(lambda v: 255 if v else 0).save(after / f'diff_{name}')
            bad += 1
        else:
            print(f'{name}: 같음')
    print('모두 같음' if bad == 0 else f'다른 그림 {bad}개')
    return 0 if bad == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
