#!/usr/bin/env python3
# Jeu 3 : le CD (édition 2001) n'a PAS le dossier de données PC en clair : il est embarqué, compressé, dans l'installeur
# Wise « install.exe » (14 Mo). Ce script en extrait les flux deflate et range ceux du jeu sous leurs vrais noms.
# Usage : wise_extract.py install.exe DOSSIER_DE_SORTIE
import struct, zlib, sys, os
src, out = sys.argv[1], sys.argv[2]
d = open(src, 'rb').read(); n = len(d)
e = struct.unpack_from('<I', d, 0x3c)[0]; nsec = struct.unpack_from('<H', d, e + 6)[0]; opt = struct.unpack_from('<H', d, e + 20)[0]
sec = e + 24 + opt; end = 0
for i in range(nsec):
    raw, ptr = struct.unpack_from('<II', d, sec + i * 40 + 16); end = max(end, ptr + raw)
os.makedirs(os.path.join(out, 'resource'), exist_ok=True)
mz = {242688: 'resource/basic.x95', 87040: 'resource/cursors.c95', 185344: 'resource/extras.r95', 66560: 'resource/rotatork.r95', 757760: 'Ile_myst.exe'}
photo = 0; pos = end; named = []
while pos < n - 16:
    dec = zlib.decompressobj(-15); buf = bytearray(); ok = False; i = pos
    try:
        while i < n:
            buf += dec.decompress(d[i:i + 65536]); i += 65536
            if dec.eof: ok = True; break
    except zlib.error:
        pass
    if not ok or len(buf) < 256:
        pos += 1; continue
    pos += (i - pos) - len(dec.unused_data) + 4      # + CRC32
    b = bytes(buf); name = None
    if b[:6] == b'\x01\x00\xa5\xa5\x55\xaa': name = 'ile_myst1.MPL'
    elif b[:2] == b'MZ' and len(b) in mz: name = mz[len(b)]
    elif b[:4] == b'\x00\x00\x01\x00' and len(b) == 3262: name = 'Ile_myst.ico'
    elif b[:8] == b'\x00\x00\x00\x00\xc7\x02\x00\x00' and b[14] == 0x32: name = 'liste_pages'
    elif b[:8] == b'\x00\x00\x00\x00\xc7\x02\x00\x00' and b[14] == 0x37: name = 'sauve'
    elif b[:8] == b'\x00\x00\x00\x00\xff\xff\xff\xff': name = 'textes_labo.dat'
    elif b[:2] == b'BM' and len(b) == 10978:
        photo += 1; name = f'photo{photo}/photo0'; os.makedirs(os.path.join(out, f'photo{photo}'), exist_ok=True)
    if name:
        open(os.path.join(out, name), 'wb').write(b); named.append((name, len(b)))
for nm, sz in named: print(f'{sz:>10}  {nm}')
missing = {'ile_myst1.MPL', 'Ile_myst.exe', 'liste_pages', 'sauve'} - {nm for nm, _ in named}
sys.exit(f'!! manquant : {missing}' if missing else 0)
