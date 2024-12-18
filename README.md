# WHANOS

## Présentation du projet

Ce projet a pour objectif de mettre en place une infrastructure DevOps complète permettant le déploiement automatique d'applications dans un cluster Kubernetes, simplement par un push sur un dépôt Git compatible. L'idée est de combiner plusieurs outils et technologies afin de disposer d'une chaîne de production entièrement automatisée et extensible.

## Technologies utilisées

- **Ansible** : Utilisé pour l'installation et le déploiement automatisé de l'infrastructure. Il permet d'assurer la cohérence, l'idempotence et la maintenabilité du déploiement, qu'il s'agisse du provisionnement des serveurs, de l'installation de Jenkins, du registre Docker ou du cluster Kubernetes.
  
- **Jenkins** : Instance CI/CD utilisée pour orchestrer les jobs de builds d'images, les déploiements de projets et la mise à jour continue du cluster Kubernetes. Jenkins est configuré avec différents jobs, dont :
  - Des jobs pour construire les images de base (Whanos base images).
  - Un job `link-project` permettant de relier un projet au pipeline et de lancer automatiquement la containerisation et le déploiement sur de nouveaux commits.
  
- **KinD (Kubernetes in Docker)** : Utilisé pour mettre en place un cluster Kubernetes local. KinD permet de disposer d'un cluster K8s complet, facile à configurer, idéal pour les environnements de développement ou d'intégration. Ce cluster sert de cible de déploiement pour les applications containerisées.
  
- **DinD (Docker in Docker)** : Permet l'utilisation de Docker au sein de l’environnement Jenkins sans impacter le système hôte. Cela permet la création, la gestion et le push des images Docker sans installation additionnelle côté hôte. DinD est utilisé afin d’offrir à Jenkins un environnement dockerisé pour construire et pousser les images.

## Structure globale

Le workflow global est le suivant :

1. **Dépôt Git du projet** : Le projet contient le code source de l'application (dans `app/`) ainsi qu'un fichier `whanos.yml` décrivant le déploiement (replicas, ressources, ports, etc.) et éventuellement un `Dockerfile` personnalisé si une image base est utilisée.

2. **Lancement du build** : Suite à un push sur le dépôt, Jenkins détecte les changements et lance automatiquement la construction de l'image docker correspondante. Cette étape s'appuie sur les images "Whanos" de base, et éventuellement sur un Dockerfile spécifique au projet.

3. **Push de l'image sur un registre Docker** : Une fois construite, l'image est poussée sur un registre Docker afin d’être déployable dans le cluster K8s.

4. **Déploiement dans le cluster Kubernetes** : Si un fichier `whanos.yml` est présent et correctement configuré, l'application est déployée dans le cluster KinD. Le cluster est configuré grâce à Ansible (et potentiellement kubespray) pour disposer d'au moins deux nœuds, et ainsi accueillir l’application.

## Lancement du projet

Après avoir cloné ce dépôt et configuré les variables d’environnement (ex. accès au registre Docker, credentials Git, etc.), vous pouvez lancer le projet simplement en exécutant :

```bash
./build.sh
```
Ce script va s’assurer de l’installation et du déploiement de l’infrastructure (via Ansible), démarrer Jenkins, configurer les jobs, lancer le cluster Kubernetes, et mettre en place l’ensemble des composants nécessaires.
