#!/usr/bin/env python3
"""Generate the demo applet's media files: orb.png (64x64 shaded sphere)
and click.wav (a short two-tone chime, 22.05 kHz 16-bit mono)."""
import math
import struct
import sys
import wave
import zlib


def png(path, w, h, pixel):
    rows = b''
    for y in range(h):
        rows += b'\0' + b''.join(struct.pack('BBBB', *pixel(x, y)) for x in range(w))

    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    with open(path, 'wb') as fh:
        fh.write(b'\x89PNG\r\n\x1a\n')
        fh.write(chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)))
        fh.write(chunk(b'IDAT', zlib.compress(rows, 9)))
        fh.write(chunk(b'IEND', b''))


def orb(x, y, n=64):
    cx = cy = (n - 1) / 2
    r = n / 2 - 1
    dx, dy = (x - cx) / r, (y - cy) / r
    d2 = dx * dx + dy * dy
    if d2 > 1:
        return (0, 0, 0, 0)
    z = math.sqrt(1 - d2)
    # light from the upper left
    lam = max(0.0, (-0.45 * dx - 0.55 * dy + 0.7 * z))
    spec = lam ** 24
    base = (40, 120, 200)
    c = [min(255, int(v * (0.25 + 0.75 * lam) + 255 * spec)) for v in base]
    alpha = 255 if d2 < 0.96 else int(255 * (1 - d2) / 0.04)
    return (c[0], c[1], c[2], alpha)


def chime(path, rate=22050):
    frames = []
    for i in range(int(rate * 0.35)):
        t = i / rate
        f = 880 if t < 0.12 else 1320
        env = math.exp(-12 * (t if t < 0.12 else t - 0.12))
        frames.append(int(9000 * env * math.sin(2 * math.pi * f * t)))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(struct.pack('<%dh' % len(frames), *frames))


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    png(out + '/orb.png', 64, 64, orb)
    chime(out + '/click.wav')
