from pathlib import Path
import sys


fix_text_lines = (Path(__file__).parent / "emcc_additional_contents.py").read_text().splitlines()


def patch_emcc(fn):
    fn = Path(fn)
    text = fn.read_text()

    lines = text.splitlines()
    for idx, l in enumerate(lines):
        if "__name__" in l and "__main__" in l:
            findex = idx - 1
    
    lines[findex:findex] = fix_text_lines
    findex += len(fix_text_lines)
    lines[findex + 2:findex + 2] = ["  scipy_fixes(sys.argv)"]

    fn.write_text('\n'.join(lines))

if __name__ == '__main__':
    patch_emcc(sys.argv[1])