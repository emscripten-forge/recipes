#!/usr/bin/env python3
"""pack-jre.py -- bundle a directory tree into OUT_PREFIX.data[.gz] + OUT_PREFIX.json for the
WebAssembly Java runtime (loaded into the in-memory file system at start).

usage: pack-jre.py SRC_DIR OUT_PREFIX [--root /java] [--gzip] [--recompress-jars]
  --gzip             write OUT_PREFIX.data.gz (gzip -9) instead of .data; the
                     loader decompresses it (smaller than compressing the
                     jars individually, and no inflating when classes load)
  --recompress-jars  store .jar files deflate-compressed (the JDK image keeps
                     rt.jar uncompressed); trades download size for a little
                     CPU time when classes are loaded.
"""
import argparse
import gzip
import io
import json
import os
import zipfile


def recompress(path):
    out = io.BytesIO()
    with zipfile.ZipFile(path) as zin, zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED,
                                                       compresslevel=9) as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            ni = zipfile.ZipInfo(info.filename, date_time=info.date_time)
            ni.external_attr = info.external_attr
            ni.compress_type = zipfile.ZIP_STORED if info.filename.endswith('/') else zipfile.ZIP_DEFLATED
            zout.writestr(ni, data)
    return out.getvalue()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('out')
    ap.add_argument('--root', default='/java')
    ap.add_argument('--gzip', action='store_true')
    ap.add_argument('--recompress-jars', action='store_true')
    a = ap.parse_args()
    dirs, files, links = [], [], []
    offset = 0
    with open(a.out + '.data', 'wb') as data:
        for root, dnames, fnames in os.walk(a.src):
            dnames.sort()
            rel = os.path.relpath(root, a.src)
            if rel != '.':
                dirs.append(rel)
            for f in sorted(fnames):
                p = os.path.join(root, f)
                r = os.path.normpath(os.path.join(rel, f))
                if os.path.islink(p):
                    links.append({'p': r, 't': os.readlink(p)})
                    continue
                if a.recompress_jars and f.endswith('.jar'):
                    blob = recompress(p)
                else:
                    with open(p, 'rb') as fh:
                        blob = fh.read()
                data.write(blob)
                mode = os.stat(p).st_mode & 0o777
                files.append({'p': r, 'o': offset, 's': len(blob), 'm': mode})
                offset += len(blob)
    index = {'root': a.root, 'size': offset, 'dirs': dirs, 'files': files, 'links': links,
             'data': os.path.basename(a.out) + '.data'}
    if a.gzip:
        with open(a.out + '.data', 'rb') as fin:
            raw = fin.read()
        with open(a.out + '.data.gz', 'wb') as fout:
            # mtime=0 and no file name: reproducible output
            with gzip.GzipFile(filename='', mode='wb', fileobj=fout, compresslevel=9, mtime=0) as gz:
                gz.write(raw)
        os.remove(a.out + '.data')
        index.update(data=os.path.basename(a.out) + '.data.gz', encoding='gzip',
                     csize=os.path.getsize(a.out + '.data.gz'))
    with open(a.out + '.json', 'w') as fh:
        json.dump(index, fh, separators=(',', ':'))
    print('pack-jre: %d files, %d bytes%s' % (len(files), offset,
          ' (%d compressed)' % index['csize'] if a.gzip else ''))


if __name__ == '__main__':
    main()
