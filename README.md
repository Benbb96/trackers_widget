# Trackers Widget

Application Flutter Android personnelle pour suivre des habitudes et événements du quotidien via une API Django REST Framework.

## Fonctionnalités

**Application**
- Liste des trackers avec compteur et date du dernier track
- Ajout d'un track avec commentaire et date personnalisable
- Historique des tracks groupé par date, scrollable
- Création de trackers (nom, couleur, icône Font Awesome)
- Réorganisation des trackers par drag & drop
- Édition et suppression des tracks et trackers

**Widget Android**
- Widget 1×1 sur l'écran d'accueil, une instance par tracker
- Tap → envoie un track instantanément
- Feedback visuel 2 secondes (✓ succès / ✗ erreur)

## Stack

- **Flutter** (Android)
- **Kotlin** pour le widget natif (`AppWidgetProvider`, `TrackActivity`)
- **`home_widget`** pour le partage de données Flutter ↔ widget
- **`flutter_secure_storage`** pour le token dans l'app
- **`font_awesome_flutter`** pour les icônes

## Configuration

1. Ouvrir l'app
2. Aller dans l'onglet **Réglages**
3. Saisir le token API Django REST Framework
4. Ajouter un widget sur l'écran d'accueil et lui assigner un tracker

## API

L'app communique avec une API DRF. Endpoints utilisés :

| Méthode | Endpoint | Action |
|---------|----------|--------|
| GET | `/tracker/api/tracker` | Liste des trackers |
| POST | `/tracker/api/tracker` | Créer un tracker |
| DELETE | `/tracker/api/tracker/{id}` | Supprimer un tracker |
| PATCH | `/tracker/api/tracker/reorder` | Réordonner |
| POST | `/tracker/api/track` | Ajouter un track |
| PATCH | `/tracker/api/track/{id}` | Modifier un track |
| DELETE | `/tracker/api/track/{id}` | Supprimer un track |

## Développement

```bash
flutter pub get
flutter run
flutter test
```
