# Personal Task Manager - Development & Deployment Guide

This guide provides instructions on how to set up, build, connect, and deploy the entire **Personal Task Manager** application stack.

---

## 🏗️ Architecture Overview

The application is structured into three main layers:
1. **Frontend**: A premium Flutter application (compiles to Android APK for mobile, and Flutter Web for web-based access).
2. **Backend**: A Node.js + Express + TypeScript REST API located in the `/backend` folder.
3. **Database**: A PostgreSQL database container serving as the central datastore.

---

## 💾 1. Database Setup & Connection

The backend uses **Prisma ORM** to interface with PostgreSQL.

### Option A: Setup using Docker (Recommended)
You can run a standalone PostgreSQL database container with this command:
```bash
docker run --name task-manager-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=personal_task_manager \
  -p 5432:5432 \
  -d postgres:15-alpine
```

### Option B: Local Setup
If you have PostgreSQL installed on your machine, create a database named `personal_task_manager`.

### Initializing the Database Schema (Prisma)
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install the backend node dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file inside the `backend` folder:
   ```env
   PORT=5000
   DATABASE_URL="postgresql://postgres:postgres@localhost:5432/personal_task_manager?schema=public"
   NODE_ENV=development
   ```
4. Generate the Prisma client:
   ```bash
   npm run prisma:generate
   ```
5. Apply the database schema migrations (this creates the Category, Task, and Subtask tables):
   ```bash
   npm run prisma:push
   ```

---

## 🚀 2. Running & Deploying the Backend API

### Development Mode (Local Host)
Starts the Express server on port `5000` with hot-reloading (`nodemon`):
```bash
cd backend
npm run dev
```

### Production Build & Launch
Compile TypeScript to production JavaScript and run the server:
```bash
cd backend
npm run build
npm start
```

---

## 🐳 3. Full-Stack Docker Deployment (Docker Compose)

You can run the Database, Backend API, and Flutter Web frontend all together using the single command.

### Launching the Stack
Run this from the project's root folder:
```bash
docker compose up --build -d
```

### Services Spawned
* **PostgreSQL Database (`db` service)**: Listens on port `5432` locally.
* **Backend API (`backend` service)**: Accessible on port `5050` (internally binds to port `5000`).
* **Frontend Web (`frontend` service)**: served on port `8080` via Nginx (serves the Flutter Web compilation).

### Volumes & Persistence
The database state is saved to a persistent Docker volume named `postgres_data`. When you restart or rebuild the containers, your database schema and user tasks will be preserved:
```yaml
volumes:
  postgres_data:
```

### Checking Logs
To view the output logs of your backend and database services:
```bash
docker compose logs -f
```

---

## 📱 4. Building the Flutter Android APK

There are two ways to compile the Android APK:

### Option A: Standard Build (Requires local SDKs)
If you have the Flutter SDK and Android SDK fully installed on your Windows machine, run:
```bash
flutter build apk --release --no-tree-shake-icons
```
The resulting APK will be saved at:
`build/app/outputs/flutter-apk/app-release.apk`

### Option B: Zero-Installation Build via Docker (Recommended)
This compiles the APK inside a sandboxed Linux builder, avoiding the need to install development environments on your computer.

Run this from the root directory:
```bash
docker build -f Dockerfile.android -o build_output .
```

* **Where the APK is exported**: Once the build completes, the fresh APK is exported directly into the `./build_output` folder in your workspace root as `app-release.apk`.
* **Caching & Speeds**: The build uses a cache mount (`id=gradle-cache-v3`) for your `/root/.gradle` directory and pub cache. This ensures subsequent builds do not download dependencies or the Android NDK from scratch, speeding up builds significantly.

---

## 🔗 5. Connecting Frontend to the Backend

### Local Storage (Default)
Out of the box, the Flutter application is configured to run fully offline using **SharedPreferences** to persist your tasks and categories directly on the device memory. This ensures maximum privacy and immediate loading.

### Connecting to the REST API Backend
If you want to sync task management across web and mobile:
1. Add the `http` package to `pubspec.yaml`:
   ```yaml
   dependencies:
     http: ^1.2.0
   ```
2. Create an `api_service.dart` to sync local operations:
   * **Android Emulator endpoint**: `http://10.0.2.2:5050/api` (default route to Windows host port).
   * **Physical Device endpoint**: `http://<your-computer-ip>:5050/api`
   * **Web / Production endpoint**: `http://localhost:5050/api` (or your domain name).
