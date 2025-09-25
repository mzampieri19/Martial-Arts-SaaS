# Martial-Arts-SaaS

## Overview
Martial-Arts-SaaS is a work-in-progress platform that pairs a Flutter frontend with a lightweight Node.js/Express backend. The goal is to provide a foundation for building scheduling, member management, and communication tools tailored to martial arts academies.

## Project Structure
- `frontend/` – Flutter application (lib/ contains screens such as the profile flow, assets/icons/ holds SVG artwork).
- `backend/` – TypeScript Express server scaffold.

## Prerequisites
- Flutter SDK (matching the constraint in `frontend/pubspec.yaml`).
- Node.js 18+ and npm for the backend.

## Getting Started
### Frontend
1. `cd frontend`
2. `flutter pub get`
3. `flutter run` *(choose a device or simulator)*

### Backend
1. `cd backend`
2. `npm install`
3. `npx ts-node src/index.ts` *(replace with your preferred start script as the API evolves)*

## Next Steps
- Flesh out backend routes/controllers in `backend/src/`.
- Connect the Flutter screens to real API endpoints.
- Add automated tests for both layers as features stabilize.

## License
This repository currently has no explicit license; add one when you are ready to distribute the project.
