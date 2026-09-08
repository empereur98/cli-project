# NX CLI (`nxt-cli`) - Générateur & Gestionnaire de Modules Nuxt 3/4

## Présentation

**NX CLI** (`nxt-cli`) est un outil en ligne de commande (CLI) multiplateforme (Linux, macOS, Windows) conçu pour automatiser et simplifier la création de projets **Nuxt 3/4** préconfigurés avec **Tailwind CSS**, ainsi que la gestion de modules Nuxt autonomes et modularisés.

Il permet de :
- Générer de nouveaux projets Nuxt clés en main avec architecture prédéfinie.
- Créer et scaffolder des modules Nuxt autonomes locaux dans `./modules/`.
- Importer des modules Nuxt distants depuis des dépôts Git (GitHub).
- Synchroniser et mettre à jour automatiquement les modules via un registre central (`nx.config.json`).
- Gérer le cycle de vie complet des modules (installation, suppression, mise à jour, listage).
- Offrir le modèle "Wrapper" (façon Maven Wrapper `./mvnw`), permettant d'embarquer la commande `./nx` directement au sein des projets générés.

---

## Prérequis

- **Node.js** (v18.x ou supérieure)
- **npm** (ou yarn/pnpm)
- **Git**
- Shell Bash (Linux/macOS, Git Bash ou WSL sous Windows)

---

## Installation et Initialisation

### Initialisation Globale (`--init`)

Pour pouvoir exécuter la commande `nx` depuis n'importe quel dossier dans votre terminal :

```bash
./nx --init
# Ou depuis le dossier nxt-cli :
./nxt-cli/nx --init
```

Cette commande crée un lien symbolique dans le PATH de votre système (`/usr/local/bin/nx` ou `~/.local/bin/nx`) ou configure les variables d'environnement sous Windows.

---

## Syntaxe Générale

```bash
nx <commande> [options] [arguments]
# Ou localement dans un projet :
./nx <commande> [options] [arguments]
```

---

## Sommaire des Commandes

| Commande / Option | Description | Exemple |
| :--- | :--- | :--- |
| `create <project_name>` | Scaffolde un nouveau projet Nuxt 3/4 avec Tailwind CSS et le wrapper `./nx` embarqué | `nx create trading-frontend` |
| `-m, --module <name>` | Scaffolde un module Nuxt autonome local dans `./modules/<name>` | `nx -m trading-auth` |
| `-i, --import [url\|name]` | Importe un module depuis GitHub ou synchronise les modules de `nx.config.json` | `nx -i user/trading-auth` |
| `-u, --update [name]` | Effectue un `git pull` pour mettre à jour un module spécifique ou tous les modules | `nx -u trading-auth` |
| `-d, --delete <name>` | Supprime un module du projet et met à jour `nuxt.config.ts` & `nx.config.json` | `nx -d trading-auth` |
| `-l, --list` | Affiche un tableau de tous les modules installés (versions, dépôts, rôles) | `nx -l` |
| `man, --man` | Affiche la page de manuel complète (`man nx`) | `nx man` |
| `-h, --help` | Affiche l'aide rapide en ligne de commande | `nx --help` |

---

## Détail des Fonctionnalités

### 1. Initialisation globale (`nx --init`)
Exécute le script `cli_initializer.sh` pour enregistrer l'exécutable `nx` dans le système (`PATH`), permettant un accès global sur Linux, macOS et Windows.

### 2. Création de Projet (`nx create <project_name>`)
Crée un projet Nuxt 3/4 complet préconfiguré :
- Configuration et intégration de **Tailwind CSS**.
- Structure d'application complète (`pages`, `components`, `composables`, `services`, `types`, `stores`).
- Génération du registre central `nx.config.json`.
- Copie de l'exécutable `./nx` à la racine du projet généré.
- Initialisation Git (`git init` et commit initial).
- Installation automatique des dépendances (`npm install`) et préparation des déclarations de types (`nuxt prepare`).

### 3. Création de Module Autonome (`nx -m <module_name>`)
Génère un module Nuxt autonome localisé dans `./modules/<module_name>` :
- Arborescence interne complète (`pages`, `components`, `composables`, `services`, `types`, `stores`).
- Fichier point d'entrée `index.ts` et page d'accueil standalone `app.vue`.
- Enregistrement automatique dans la section `modules` du fichier `nuxt.config.ts` du projet hôte.
- Intégration de Tailwind CSS et initialisation d'un dépôt Git dédié pour le module.

### 4. Importation de Module Distant (`nx -i <url_ou_raccourci>`)
- Clone un module distant depuis une URL GitHub ou un raccourci `utilisateur/depot` dans le dossier `./modules/`.
- Ajoute automatiquement le module à `nuxt.config.ts` et au registre `nx.config.json`.
- En exécutant `nx -i` sans argument, la CLI parcourt `nx.config.json` et synchronise tous les modules distants du projet.

### 5. Mise à jour des Modules (`nx -u [module_name]`)
- Met à jour le code source d'un module spécifique (`nx -u <name>`) ou de tous les modules (`nx -u`) en exécutant `git pull origin <branch>`.
- Regénère les types TypeScript Nuxt avec `npx nuxt prepare`.

### 6. Suppression de Module (`nx -d <module_name>`)
- Supprime le répertoire physique du module (`./modules/<module_name>`).
- Désinscrit proprement le module de `nuxt.config.ts` et du registre `nx.config.json`.
- Exécute `nuxt prepare` pour rafraîchir les types TypeScript du projet.

### 7. Liste des Modules (`nx -l`)
Affiche un tableau lisible récapitulant les modules installés :
- Nom du module
- Version détectée (tag Git ou `package.json`)
- Dépôt distant (origin URL ou Local)
- Description / Rôle du module

### 8. Page de Manuel & Aide (`nx man` / `nx --help`)
- `nx man` ouvre la documentation système au format `man`.
- `nx -h` ou `nx --help` affiche la synthèse d'utilisation directement dans la console.

---

## Architecture du Répertoire `nxt-cli`

```
nxt-cli/
├── nx                       # Script d'entrée principal Bash
├── nx.cmd                   # Wrapper d'exécution pour Windows CMD
├── nx.ps1                   # Wrapper d'exécution pour PowerShell
├── README.md                # Documentation complète de la commande CLI
├── lib/                     # Modules et handlers de la CLI
│   ├── cli_initializer.sh   # Logique d'initialisation globale (--init)
│   ├── cli_parser.sh        # Parseur d'arguments et routage des commandes
│   ├── git_handler.sh       # Utilitaires Git (init, commit, push)
│   ├── help_formatter.sh    # Mise en forme de l'aide CLI (--help)
│   ├── man_viewer.sh        # Visionneuse de la page man (nx man)
│   ├── module_creator.sh    # Générateur de modules autonomes (-m)
│   ├── module_importer.sh   # Importateur de modules distants (-i)
│   ├── module_lister.sh     # Affichage de la liste des modules (-l)
│   ├── module_remover.sh    # Suppresseur de modules (-d)
│   ├── module_updater.sh    # Gestionnaire de mises à jour (-u)
│   ├── progress_bar.sh      # Animation de barre de progression CLI
│   ├── project_creator.sh   # Générateur de projets Nuxt (create)
│   ├── tailwind_installer.sh # Configuration automatique de Tailwind CSS
│   └── template_generator.sh# Moteur de rendu des templates
├── man/
│   └── nx.1                 # Page de manuel UNIX
└── templates/               # Templates de projets, modules et structures
```

---

## Auteur et Licence

Développé par l'équipe **Google DeepMind Advanced Agentic Coding**.
