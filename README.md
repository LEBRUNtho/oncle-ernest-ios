# L'oncle Ernest sur iOS

**Les cinq jeux de la série *Les Aventures de l'oncle Ernest* (Lexis Numérique / Emme, 1998-2004), jouables sur
iPhone et iPad, en plein écran et au doigt.** Version bêta.

| | Jeu | App |
|---|---|---|
| 1 | L'Album secret de l'oncle Ernest | L'Album |
| 2 | Le Fabuleux Voyage de l'oncle Ernest | Le Voyage |
| 3 | L'Île mystérieuse de l'oncle Ernest | L'Île |
| 4 | Le Temple perdu de l'oncle Ernest | Le Temple |
| 5 | La Statuette maudite de l'oncle Ernest | La Statuette |

## Ce que ça apporte

- Les jeux d'origine, complets, qui tournent nativement sur iPhone et iPad récents (pas d'émulation Windows).
- Des contrôles pensés pour le doigt : toucher pour cliquer, glisser pour déplacer les objets.
- Un menu des marque-pages pour voyager d'une page à l'autre comme dans l'album.
- Des icônes redessinées en haute définition.
- Des sauvegardes visibles dans l'app Fichiers, à copier d'un appareil à l'autre.
- Chaque jeu a été joué de bout en bout pendant le portage.

## Installation

Il faut **votre propre CD du jeu** (ou son image ISO) : les jeux ne sont pas fournis ici.

1. Téléchargez le **préparateur** dans la [dernière version](../../releases) et dézippez-le.
2. Installez [Python 3](https://www.python.org/downloads/) si vous ne l'avez pas.
3. Lancez le préparateur en double-cliquant sur le fichier de votre système (macOS, Windows ou Linux), glissez
   l'image de votre CD dans la fenêtre, appuyez sur Entrée.
4. Quelques secondes à quelques minutes plus tard, l'application `.ipa` est dans le dossier `apps`.
5. Installez-la avec votre outil de sideloading habituel (Feather, AltStore, Sideloadly...).

Le préparateur reconnaît le jeu tout seul et accepte une image `.iso`, une archive `.7z` ou `.zip` qui la contient,
ou le dossier du CD.

## Bêta : ce qu'il faut savoir

- Les jeux 1 à 3 ont été testés sur un iPhone ; les jeux 4 et 5 pour l'instant sur Mac et au simulateur seulement.
  D'autres appareils peuvent réserver des surprises.
- Le préparateur a été vérifié sur macOS ; les lanceurs Windows et Linux sont neufs et restent à éprouver.
- Le son et quelques mini-jeux d'adresse des jeux 4 et 5 méritent encore des retours.

Un souci, une idée ? Ouvrez une *issue* en précisant le jeu, votre appareil et ce qui s'est passé.

## Pour les curieux

Le dossier `sources/` contient de quoi reconstruire les applications sur un Mac : les modifications apportées à
[ScummVM](https://www.scummvm.org) (moteurs mTropolis et Director) et les scripts de construction.

## D'où ça vient

Petit projet perso : j'ai grandi avec ces jeux, ils ne tournaient plus nulle part, alors je m'amuse avec une IA
(Claude) à les faire revivre sur iPhone et iPad. Rien de professionnel, aucune prétention.

## Droits

Les jeux, leurs personnages, images, musiques, voix et textes appartiennent à leurs ayants droit : Lexis Numérique,
l'éditeur Emme Interactive et ses successeurs, ainsi que les héritiers d'Éric Viennot (1960-2022), créateur de la
série. Ce projet n'a aucun lien avec eux, n'est pas officiel, ne fournit aucun fichier des jeux et ne rapporte rien
à personne.

Si vous êtes ayant droit et que quelque chose ici vous gêne, ouvrez une *issue* : le contenu concerné sera retiré
rapidement, sans discussion.

Merci à Éric Viennot et à toute l'équipe de Lexis Numérique pour ces jeux.

## Licence

Les applications et les modifications de ScummVM sont sous licence GPL version 3 ou ultérieure (voir `LICENSE`),
comme ScummVM, projet indépendant qui n'a rien à voir avec ce portage.
