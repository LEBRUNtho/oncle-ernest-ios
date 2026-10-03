#!/usr/bin/env python3
# Préparateur L'oncle Ernest pour iOS : transforme le CD d'un des 5 jeux (image ISO, archive .7z/.zip contenant
# l'ISO, ou dossier du CD) en application iPhone (.ipa) non signée, à installer avec un outil de sideloading.
# Usage : python preparer.py CHEMIN_DU_CD [DOSSIER_DE_SORTIE]
import os, re, sys, glob, shutil, struct, zipfile, tempfile, subprocess, fnmatch

ICI = os.path.dirname(os.path.abspath(__file__))
COQUILLES = os.path.join(ICI, 'coquilles')

JEUX = {
    'album':     ('L\'Album secret de l\'oncle Ernest', 'AlbumErnest'),
    'voyage':    ('Le Fabuleux Voyage de l\'oncle Ernest', 'VoyageErnest'),
    'ile':       ('L\'Île mystérieuse de l\'oncle Ernest', 'IleErnest'),
    'temple':    ('Le Temple perdu de l\'oncle Ernest', 'TempleErnest'),
    'statuette': ('La Statuette maudite de l\'oncle Ernest', 'StatuetteErnest'),
}

def dire(*a):
    print(*a, flush=True)

# ---------------------------------------------------------------- lecture des sources (ISO, archive, dossier)

class Source:
    """Arborescence du CD : chemins relatifs (avec la casse d'origine) -> lecture du contenu."""
    def __init__(self, fichiers, lire, extraire):
        self.fichiers = fichiers          # liste de chemins relatifs
        self._lire = lire
        self._extraire = extraire
        self.min = {p.lower(): p for p in fichiers}
    def trouve(self, chemin):
        return self.min.get(chemin.lower())
    def lire(self, chemin):
        return self._lire(chemin)
    def extraire(self, chemin, dest):
        os.makedirs(os.path.dirname(dest) or '.', exist_ok=True)
        self._extraire(chemin, dest)

def source_iso(chemin):
    import pycdlib
    iso = pycdlib.PyCdlib()
    iso.open(chemin)
    ns = 'rr_path' if iso.has_rock_ridge() else ('joliet_path' if iso.has_joliet() else 'iso_path')
    vrai = {}
    for racine, dossiers, fichiers in iso.walk(**{ns: '/'}):
        for f in fichiers:
            nom = f.split(';')[0].rstrip('.') if ns == 'iso_path' else f
            vrai[(racine.rstrip('/') + '/' + nom).lstrip('/')] = racine.rstrip('/') + '/' + f
    def extraire(p, dest):
        iso.get_file_from_iso(dest, **{ns: vrai[p]})
    def lire(p):
        import io
        b = io.BytesIO(); iso.get_file_from_iso_fp(b, **{ns: vrai[p]}); return b.getvalue()
    return Source(list(vrai), lire, extraire)

def source_dossier(racine):
    fichiers = []
    for dp, dn, fn in os.walk(racine):
        for f in fn:
            fichiers.append(os.path.relpath(os.path.join(dp, f), racine).replace(os.sep, '/'))
    return Source(fichiers, lambda p: open(os.path.join(racine, p), 'rb').read(),
                  lambda p, dest: shutil.copyfile(os.path.join(racine, p), dest))

def ouvrir(chemin, temp):
    """Renvoie une Source, en dépliant au besoin une archive .7z / .zip qui contient l'ISO ou les fichiers du CD."""
    if os.path.isdir(chemin):
        isos = glob.glob(os.path.join(chemin, '**', '*.iso'), recursive=True)
        return source_iso(isos[0]) if isos and len(os.listdir(chemin)) <= 3 else source_dossier(chemin)
    bas = chemin.lower()
    if bas.endswith('.iso'):
        return source_iso(chemin)
    if bas.endswith('.7z') or bas.endswith('.zip'):
        dest = os.path.join(temp, 'archive')
        dire('   dépliage de l\'archive (quelques minutes)...')
        if bas.endswith('.7z'):
            import py7zr
            with py7zr.SevenZipFile(chemin, 'r') as z: z.extractall(dest)
        else:
            with zipfile.ZipFile(chemin) as z: z.extractall(dest)
        isos = glob.glob(os.path.join(dest, '**', '*.iso'), recursive=True)
        return source_iso(isos[0]) if isos else source_dossier(dest)
    # dernier essai : une image disque sans extension connue
    return source_iso(chemin)

def reconnaitre(src):
    if src.trouve('album422.MPX'): return 'album'
    if src.trouve('voyage2.MPX'): return 'voyage'
    if src.trouve('ile_myst2.MPX'): return 'ile'
    if src.trouve('Media/LeTemplePerdu.exe') or src.trouve('LeTemplePerdu.ico'): return 'temple'
    if src.trouve('ernest5.ico') or any(p.lower().startswith('media/dir/s07d') for p in src.fichiers): return 'statuette'
    return None

# ---------------------------------------------------------------- recettes : quels fichiers vont dans l'app

def sous(src, prefixe, sauf_dossier=None):
    """Fichiers sous un dossier du CD -> (chemin dans l'app, chemin sur le CD)."""
    out = []
    for p in src.fichiers:
        if p.lower().startswith(prefixe.lower().rstrip('/') + '/'):
            rel = p[len(prefixe.rstrip('/')) + 1:]
            if sauf_dossier and rel.lower().startswith(sauf_dossier.lower() + '/'):
                continue
            out.append((rel, p))
    return out

def recette_album(src, temp):
    return sous(src, 'Album/Data') + [('album422.MPX', src.trouve('album422.MPX'))]

def recette_voyage(src, temp):
    L = sous(src, 'voyage/data', sauf_dossier='resource')
    L += [('Video/' + r, p) for r, p in sous(src, 'Video')]
    L += [('voyage2.MPX', src.trouve('voyage2.MPX'))]
    res = {r.lower(): (r, p) for r, p in sous(src, 'voyage/data/resource')}
    bmp = src.trouve('9598me/data/resource/bitmap.r95')     # version 95/98/ME du plugin, celle attendue
    if bmp: res['bitmap.r95'] = ('bitmap.r95', bmp)
    L += [('resource/' + r.lower(), p) for r, p in res.values()]
    return L

def recette_ile(src, temp):
    inst = os.path.join(temp, 'install.exe')
    src.extraire(src.trouve('install.exe'), inst)
    wise = os.path.join(temp, 'wise')
    subprocess.run([sys.executable, os.path.join(ICI, 'wise_extract.py'), inst, wise], check=True, stdout=subprocess.DEVNULL)
    L = [(os.path.relpath(os.path.join(dp, f), wise).replace(os.sep, '/'), None, os.path.join(dp, f))
         for dp, dn, fn in os.walk(wise) for f in fn]
    L = [x for x in L if not x[0].lower().startswith('resource/bitmap')]
    L += [('ile_myst2.MPX', src.trouve('ile_myst2.MPX'))]
    L += [('Video/' + r, p) for r, p in sous(src, 'Video')]
    L += [('resource/bitmap.r95', src.trouve('9598me/data/resource/bitmap.r95'))]
    return L

EXCL_DIRECTOR = ['qtime/*', 'autorun.exe', 'install.exe', 'garantie.exe', 'pr.exe', '*.bmp', 'autorun.inf']
EXCL_STATUETTE = EXCL_DIRECTOR + ['padding.dat', 'media/protect.dll', 'install.ini', 'emme.wri', 'fithle.txt', 'ernest5.ico']

def recette_director(src, exclus):
    """Tout le CD, sauf l'installeur Windows et ses fichiers (motifs relatifs à la racine du CD)."""
    L = []
    for p in src.fichiers:
        b = p.lower()
        def exclu(e):
            if '/' in e: return fnmatch.fnmatch(b, e)
            return '/' not in b and fnmatch.fnmatch(b, e)
        if not any(exclu(e) for e in exclus):
            L.append((p, p))
    return L

def recette_temple(src, temp):
    return recette_director(src, EXCL_DIRECTOR)

def recette_statuette(src, temp):
    return recette_director(src, EXCL_STATUETTE)

RECETTES = {'album': recette_album, 'voyage': recette_voyage, 'ile': recette_ile,
            'temple': recette_temple, 'statuette': recette_statuette}

# ---------------------------------------------------------------- vidéos Sorenson 3 -> Sorenson 1 (jeux 4 et 5)

def ffmpeg():
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()

def est_svq3(chemin):
    with open(chemin, 'rb') as f:
        d = f.read(4 * 1024 * 1024)
    return b'SVQ3' in d

def convertir(chemin, temp):
    sortie = os.path.join(temp, 'conv_' + os.path.basename(chemin))
    subprocess.run([ffmpeg(), '-hide_banner', '-loglevel', 'error', '-y', '-i', chemin,
                    '-vf', 'scale=in_range=full:out_range=limited', '-c:v', 'svq1', '-qscale:v', '3',
                    '-pix_fmt', 'yuv410p', '-c:a', 'adpcm_ima_qt', '-f', 'mov', sortie], check=True)
    os.replace(sortie, chemin)

# ---------------------------------------------------------------- fabrication de l'IPA

def fabriquer(cd, sortie_dir):
    temp = tempfile.mkdtemp(prefix='ernest_')
    try:
        dire('== Lecture du CD :', cd)
        src = ouvrir(cd, temp)
        jeu = reconnaitre(src)
        if not jeu:
            sys.exit('!! Ce CD n\'est pas reconnu comme un jeu de l\'oncle Ernest.')
        titre, app = JEUX[jeu]
        dire('   jeu reconnu :', titre)
        coquille = os.path.join(COQUILLES, app + '-coquille.ipa')
        if not os.path.exists(coquille):
            sys.exit('!! Coquille introuvable : ' + coquille)
        dire('== Extraction des données du jeu')
        jeu_dir = os.path.join(temp, 'game')
        for x in RECETTES[jeu](src, temp):
            dest = os.path.join(jeu_dir, *x[0].split('/'))
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if len(x) == 3: shutil.copyfile(x[2], dest)
            else: src.extraire(x[1], dest)
        if jeu in ('temple', 'statuette'):
            assets = [os.path.join(dp, f) for dp, dn, fn in os.walk(jeu_dir) for f in fn if f.lower().endswith('.mov')]
            a_convertir = [v for v in assets if est_svq3(v)]
            for v in a_convertir:
                dire('   conversion de la vidéo', os.path.basename(v), '(une à deux minutes)')
                convertir(v, temp)
        dire('== Assemblage de l\'app')
        os.makedirs(sortie_dir, exist_ok=True)
        ipa = os.path.join(sortie_dir, app + '-iOS.ipa')
        with zipfile.ZipFile(coquille) as zc, zipfile.ZipFile(ipa, 'w', zipfile.ZIP_DEFLATED) as zo:
            racine = None
            for i in zc.infolist():
                zo.writestr(i, zc.read(i.filename))
                if racine is None and i.filename.startswith('Payload/') and i.filename.count('/') >= 2:
                    racine = '/'.join(i.filename.split('/')[:2])
            for dp, dn, fn in os.walk(jeu_dir):
                for f in sorted(fn):
                    p = os.path.join(dp, f)
                    rel = os.path.relpath(p, jeu_dir).replace(os.sep, '/')
                    zo.write(p, racine + '/game/' + rel)
        dire('== Terminé :', ipa, '(%d Mo)' % (os.path.getsize(ipa) // 2**20))
        dire('   À installer sur iPhone ou iPad avec un outil de sideloading (Feather, AltStore, Sideloadly...).')
        return ipa
    finally:
        shutil.rmtree(temp, ignore_errors=True)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit('Usage : preparer CHEMIN_DU_CD (image .iso, archive .7z/.zip, ou dossier) [DOSSIER_DE_SORTIE]')
    fabriquer(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.getcwd(), 'apps'))
