# NX CLI (`nxt-cli`) - Générateur & Gestionnaire de Modules Nuxt 3/4 (Feature-Driven Architecture)

[![Nuxt 3/4](https://img.shields.io/badge/Nuxt-3%20%7C%204-00DC82?logo=nuxt.js&logoColor=white)](https://nuxt.com)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v3%2Fv4-38B2AC?logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com)
[![PowerShell Native](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?logo=powershell&logoColor=white)](https://github.com)

**NX CLI** (`nxt-cli`) est un outil en ligne de commande (CLI) multiplateforme (**Windows PowerShell natif, Linux, macOS**) conçu pour automatiser et orchestrer le développement d'applications **Nuxt 3/4** selon les principes du **Feature-Driven Development** (FDD / Tranches verticales).

---

## 🚀 Démarrage Rapide : Vous venez de cloner ce dépôt ?

Si vous venez de faire `git clone` de ce dépôt sur votre machine, voici exactement comment l'activer et l'utiliser en moins d'une minute :

### Étape 1 : Initialiser la commande globale `nx`

Ouvrez votre terminal dans le dossier du dépôt cloné :

- **Sous Windows (PowerShell) :**
  ```powershell
  cd nxt-cli
  .\nx.ps1 --init
  ```
- **Sous Linux / macOS / Git Bash :**
  ```bash
  cd nxt-cli
  chmod +x nx
  ./nx --init
  ```

> [!TIP]
> **Fermez et rouvrez votre terminal** après cette commande pour que votre système recharge la variable d'environnement `PATH`.

### Étape 2 : Vérifier que la CLI répond

Tapez simplement :
```bash
nx --help
```
Si l'aide s'affiche avec la liste des commandes, **la CLI est installée avec succès sur votre machine** !

---

## 🧭 Guide Complet : Quel est votre cas d'usage ?

Ce dépôt couvre **deux scénarios distincts** :

### Scénario A : Vous voulez créer un nouveau projet Nuxt
1. Placez-vous dans votre dossier habituel de projets (ex: `c:\projets` ou `~/projets`) :
   ```bash
   cd ~/projets
   ```
2. Créez un projet préconfiguré Nuxt 3/4 + Tailwind :
   ```bash
   nx create mon-dashboard
   ```
3. Entrez dans le projet créé :
   ```bash
   cd mon-dashboard
   ```
4. Scaffoldez vos fonctionnalités métier (Feature Modules) :
   ```bash
   nx -m auth
   nx -m billing
   ```
5. Lancez votre application :
   ```bash
   npm run dev
   ```
   - Application principale : `http://localhost:3000/`
   - Feature Auth : `http://localhost:3000/auth`
   - Feature Billing : `http://localhost:3000/billing`

---

### Scénario B : Vous avez cloné un projet Nuxt existant (embarquant le wrapper `./nx`)
Si un collègue vous a partagé un projet Nuxt déjà généré avec `nxt-cli` :
**Vous n'avez même pas besoin d'installer la CLI globale !** Le projet embarque son propre wrapper portable (façon `./mvnw`).

1. Entrez dans le projet et installez les dépendances :
   ```bash
   cd mon-dashboard
   npm install
   ```
2. Utilisez le wrapper embarqué directement :
   - **Sous Windows :** `.\nx.ps1 -m nouvelle-feature`
   - **Sous Linux / macOS :** `./nx -m nouvelle-feature`
3. Démarrez le projet :
   ```bash
   npm run dev
   ```

---

## 📋 Sommaire des Commandes

| Commande | Où l'exécuter | Action | Exemple |
| :--- | :--- | :--- | :--- |
| `nx --init` | Dossier `nxt-cli/` | Enregistre l'exécutable `nx` dans le `PATH` utilisateur | `.\nx.ps1 --init` |
| `nx create <nom>` | Dossier parent (ex: `~/projets`) | Crée un projet Nuxt 3/4 avec Tailwind CSS et le wrapper embarqué | `nx create store-app` |
| `nx -m <feature>` | **Racine du projet Nuxt** | Scaffolde un Feature Module dans `./modules/<feature>` | `nx -m auth` |
| `nx -l` | **Racine du projet Nuxt** | Affiche le tableau des modules installés | `nx -l` |
| `nx -d <feature>` | **Racine du projet Nuxt** | Supprime un module proprement (fichiers + configs) | `nx -d auth` |
| `nx -i [url]` | **Racine du projet Nuxt** | Importe un module distant depuis GitHub | `nx -i user/repo` |
| `nx -u [feature]` | **Racine du projet Nuxt** | Met à jour un module distant (`git pull`) | `nx -u auth` |
| `nx -p <feature> [msg]` | **Racine du projet Nuxt** | Pousse les modifications vers le dépôt distant du module | `nx -p auth "feat: login"` |
| `nx --help` | N'importe où | Affiche l'aide synthétique | `nx --help` |
| `nx man` | N'importe où | Ouvre le manuel d'utilisation complet | `nx man` |

---

## 🏗️ Architecture d'un Projet Piloté par la CLI

Voici à quoi ressemble un projet Nuxt généré et orchestré avec `nxt-cli` :

```text
mon-dashboard/
│
├── .nuxt/                               # Cache & déclarations TypeScript Nuxt (généré par nuxt prepare)
├── node_modules/                        # UNIQUE dossier de paquets pour tout le projet
│
├── nxt-cli/                             # MOTEUR EMBARQUÉ DE LA CLI (Wrapper autonome)
│   ├── lib/                             # Modules de commandes (PowerShell & Bash)
│   └── templates/                       # Modèles de code (pages, composants, index.ts)
│
├── nx                                   # Wrapper d'exécution pour Linux / macOS / WSL
├── nx.cmd                               # Wrapper d'exécution pour Windows CMD
├── nx.ps1                               # Wrapper d'exécution pour Windows PowerShell
│
├── nuxt.config.ts                       # Configuration Nuxt hôte (enregistre les modules)
├── nx.config.json                       # Registre central des modules installés
├── package.json                         # Dépendances partagées (Vue, Nuxt, Tailwind, Pinia)
├── tsconfig.json                        # Typage TypeScript racine
│
├── app/                                 # APPLICATION HÔTE (Shell applicatif)
│   ├── app.vue                          # Point d'entrée visuel unique
│   ├── pages/                           # Pages globales (ex: accueil /)
│   ├── components/                      # Composants transverses (Header, Sidebar, Navbar)
│   ├── composables/                     # Logique transverse partagée
│   ├── layouts/                         # Layouts (default.vue)
│   └── assets/                          # Styles globaux (Tailwind CSS)
│
└── modules/                             # FEATURE MODULES (Tranches verticales créées par 'nx -m')
    │
    ├── auth/                            # Exemple : Feature Module Authentification
    │   ├── index.ts                     # Câblage Nuxt Kit (components, imports, extendPages)
    │   ├── pages/                       # Route injectée : http://localhost:3000/auth
    │   │   ├── index.vue
    │   │   └── README.md
    │   ├── components/                  # Composants auto-importés (<AuthLoginForm />)
    │   ├── composables/                 # Composables auto-importés (useAuth())
    │   ├── services/                    # Logique métier et API (authService.ts)
    │   ├── types/                       # Typages TypeScript (auth.types.ts)
    │   └── stores/                      # Store Pinia (authStore.ts)
    │
    └── billing/                         # Exemple : Feature Module Facturation
        ├── index.ts                     # Route injectée : http://localhost:3000/billing
        └── ...
```

---

## 🎯 Principes Clés du Feature-Driven Development (FDD) dans cette CLI

1. **Aucun `node_modules` local :**
   Un module métier ne doit jamais posséder son propre `package.json` ni son propre dossier `node_modules`. Toutes les dépendances sont centralisées à la racine pour éviter les conflits de versions Vue/Nuxt et accélérer l'exécution.

2. **Auto-câblage complet via `@nuxt/kit` :**
   Dès la création du module, son fichier `index.ts` déclare immédiatement à Nuxt :
   - `addComponentsDir` : les composants Vue sont auto-importés globalement.
   - `addImportsDir` : les composables, services et stores sont immédiatement utilisables sans import manuel.
   - `extendPages` : la page du module (`pages/index.vue`) est injectée dans le routeur principal (accessible sur `http://localhost:3000/<nom_du_module>`).

3. **Contexte Projet Obligatoire :**
   La commande `nx -m` vérifie impérativement la présence de `nuxt.config.ts`. Si elle est lancée hors d'un projet, elle refuse la création pour empêcher la prolifération de modules orphelins.

4. **Un seul serveur de développement :**
   Au lieu de lancer plusieurs terminaux avec différents serveurs Node.js, un unique `npm run dev` à la racine fait tourner l'ensemble du projet hôte et de tous ses modules.

---

## 🛠️ Dépannage & FAQ (Troubleshooting)

### 1. Sur Windows : « L'exécution de scripts est désactivée sur ce système »
Si PowerShell bloque l'exécution de `.\nx.ps1` avec un message sur l'`ExecutionPolicy`, autorisez temporairement l'exécution pour la session :
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### 2. Sur Windows : « /bin/bash: nx: No such file or directory »
Ce message signifie que votre système utilise une ancienne version de wrapper qui cherchait à appeler Bash.
- Assurez-vous d'utiliser la commande depuis le dépôt `nxt-cli` mis à jour.
- Si vous avez copié la CLI dans `C:\Program Files\nxt-cli`, veillez à y copier les fichiers récents (`nx.cmd` et `nx.ps1`) qui appellent nativement PowerShell sans passer par Bash.

### 3. Sur Linux / macOS : « Permission denied: ./nx »
Rendez le fichier exécutable avec la commande Unix standard :
```bash
chmod +x nx
```

### 4. Pourquoi la commande `nx -m` affiche une erreur « Must run inside an existing Nuxt project » ?
Parce que vous devez vous déplacer à la racine de votre projet Nuxt (`cd mon-projet`) avant de créer un module. Une feature ne peut pas être créée dans le vide.

---

## 📁 Architecture Interne du Dépôt `nxt-cli`

```text
nxt-cli/
├── nx                       # Point d'entrée Bash (Linux / macOS)
├── nx.cmd                   # Wrapper d'appel Windows CMD
├── nx.ps1                   # Point d'entrée PowerShell (Windows natif)
├── README.md                # Guide complet
├── lib/
│   ├── CliInitializer.ps1   / cli_initializer.sh    # Initialisation PATH (--init)
│   ├── GitHandler.ps1       / git_handler.sh        # Gestion des commandes Git
│   ├── HelpFormatter.ps1    / help_formatter.sh     # Affichage de l'aide (--help)
│   ├── ManViewer.ps1        / man_viewer.sh         # Affichage page man (man)
│   ├── ModuleCreator.ps1    / module_creator.sh     # Création Feature Module (-m)
│   ├── ModuleImporter.ps1   / module_importer.sh    # Import Git de modules (-i)
│   ├── ModuleLister.ps1     / module_lister.sh      # Liste des modules (-l)
│   ├── ModulePusher.ps1     / module_pusher.sh      # Push vers le dépôt du module (-p)
│   ├── ModuleRemover.ps1    / module_remover.sh     # Suppression de modules (-d)
│   ├── ModuleUpdater.ps1    / module_updater.sh     # Mise à jour Git (-u)
│   ├── ProgressBar.ps1      / progress_bar.sh       # Indicateurs de progression
│   ├── ProjectCreator.ps1   / project_creator.sh    # Générateur de projet (create)
│   └── TailwindInstaller.ps1/ tailwind_installer.sh # Configuration Tailwind
├── man/
│   └── nx.1                 # Documentation UNIX man
└── templates/               # Modèles de code Nuxt 3/4 & Feature Modules (sans playground)
```
