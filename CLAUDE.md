# Les cartes d'équipe · consignes pour Claude Code

Tu aides une personne qui débute à construire sa première application métier :
un tableau de cartes d'équipe, à la Trello, sur PocketBase. Le besoin complet
est dans `PRD.md`. Lis-le avant de proposer quoi que ce soit.

## Où on en est

Le projet se construit en trois parties. **La partie 1 est faite**, avec un
premier écran en lecture seule.

1. **Les données** : faite.
   - Collections dans `pb_migrations/` : `users` (fournie par PocketBase,
     champs `name` et `avatar`), `projets` (`nom`, `membres`, `couverture`) et `cartes`
     (`titre`, `projet`, `responsable`, `echeance`, `statut`, `position`,
     `date_fin`).
   - `statut` vaut « À faire », « En cours » ou « Fait ». `position` est la
     place de la carte dans sa colonne.
   - Un projet de démonstration : Léa, Karim, six cartes. Léa et Karim n'ont
     pas de photo : l'écran affiche une pastille à l'initiale du prénom (une
     personne qui ajoute un `avatar` voit sa photo à la place).
   - Règles d'accès : tout le monde peut LIRE projets, cartes et noms des
     utilisateurs (l'e-mail reste masqué). Créer, modifier, supprimer :
     fermé pour l'instant.
2. **Les fonctions** : à faire.
3. **L'interface** : à faire (l'écran actuel ne fait qu'afficher).

Le premier écran est `pb_public/index.html` : HTML, CSS et JavaScript simples,
avec le SDK de PocketBase copié dans `pb_public/pocketbase.umd.js`. Les
couleurs sont des variables CSS en tête de fichier.

## Ce qui vient ensuite, une partie à la fois

### Partie 2 · les fonctions
- Créer une carte dans un projet.
- La déplacer : changer son statut et sa place dans la colonne.
- Une carte qui passe en « Fait » prend sa date de fin toute seule, côté
  serveur (un hook PocketBase dans `pb_hooks/`), sans que personne ne la
  saisisse.

Il faudra ouvrir l'écriture des cartes : en local, une règle d'accès vide
(`""`) suffit, par une nouvelle migration. Pas d'écran de connexion à cette
étape : il fait partie de la liste « Avant toute mise en ligne », plus bas.

Le dossier `pb_hooks/` est déjà là et PocketBase le surveille : un fichier
`*.pb.js` posé dedans se recharge tout seul, sans relancer le serveur.

**Vérification** : une carte passée en « Fait » reçoit sa date de fin. Montre
la carte avant et après, dans l'écran ou dans le tableau d'administration.

### Partie 3 · l'interface
- Un tableau par projet, en trois colonnes, une par statut (déjà affiché).
- Le glisser-déposer des cartes, à la souris comme au doigt. Une
  bibliothèque qui gère le toucher fait gagner du temps (SortableJS, par
  exemple) : propose-la, ne l'impose pas.
- La carte bouge aussi sur l'écran des autres, en direct (le temps réel de
  PocketBase : `pb.collection("cartes").subscribe("*", …)`).

**Vérification** : l'app ouverte dans deux fenêtres côte à côte ; une carte
glissée dans l'une bouge dans l'autre, sans recharger la page.

## Les règles du jeu

- **Propose ton plan avant de coder**, en quelques lignes, et attends l'accord.
- **Une partie à la fois**, dans l'ordre. Ne commence pas la partie 3 avant
  que la vérification de la partie 2 soit passée.
- **Demande avant d'installer quoi que ce soit** (bibliothèque, outil, compte).
- **Reste en HTML et JavaScript simples dans `pb_public/`** : pas de framework,
  pas d'étape de build. Le code doit rester lisible par quelqu'un qui débute.
- **Une structure qui change passe par une nouvelle migration** dans
  `pb_migrations/`, jamais en modifiant une migration déjà jouée.
- **L'interface est en français**, avec les accents.
- Pour lancer le tableau : `./demarrer` (Mac) ou `demarrer.bat` (Windows).
  Le serveur occupe le terminal tant qu'il tourne : si c'est toi qui le
  lances, fais-le en arrière-plan. Pour repartir de zéro : arrêter, supprimer
  `pb_data/`, relancer (le compte d'administration est à recréer).
- Version de PocketBase : **0.40.5**. Vérifie son API dans le fichier
  `pb_data/types.d.ts` (créé au premier lancement), pas de mémoire : elle a
  beaucoup changé d'une version à l'autre.

## Avant toute mise en ligne

Ce kit tourne sur l'ordinateur de la personne, avec des comptes de
démonstration. Avant de le mettre sur internet, il faudra :
- de vrais comptes, un écran de connexion, et supprimer Léa et Karim ;
- des règles d'accès fermées : l'écriture des cartes réservée aux personnes
  connectées (`@request.auth.id != ""`), la lecture aux membres du projet ;
- un mot de passe solide pour le compte d'administration.

Rappelle-le si la personne parle de mettre l'application en ligne.
