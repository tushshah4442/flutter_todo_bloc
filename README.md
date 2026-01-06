# 📝 Flutter Todo Application - Clean Architecture

A comprehensive Task Management mobile application built with **Flutter**, strictly adhering to **Clean Architecture** principles and the **BLoC** pattern.

---

## 🚀 Features

### ✅ Assignment Core Features
*   **Task List**: View a scrollable list of tasks fetched from the API.
*   **Add Task**: Create new tasks using a Floating Action Button (FAB).
*   **Mark as Complete**: Toggle task status (checkbox) with **Optimistic UI Updates** (instant feedback).
*   **Delete Task**: Swipe-to-delete functionality with a confirmation dialog.
*   **API Integration**: Full integration with `JSONPlaceholder` (GET, POST, PATCH, DELETE).

### ⚡ Advanced Features (Bonus)
*   **Offline Support**:
    *   **Local Caching**: Tasks are cached using **Hive** NoSQL database.
    *   **Offline Mode**: App works fully without internet.
    *   **Smart Sync**: Merges local-only data with server data seamlessly.
*   **Search**: Real-time filtering of tasks by title.
*   **Pull-to-Refresh**: Syncs latest data from server while preserving local changes.
*   **Authentication**: Mock Login system (`admin@azodha.com` / `password123`) with persistent session management.

---

## 🏃‍♂️ Setup Instructions

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/tushshah4442/flutter_todo_bloc.git
    cd flutter_todo_bloc
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Generate Code (Crucial Step)**:
    This project uses `Hive` for local storage, which requires type adapters. Run the build runner to generate them:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the App**:
    ```bash
    flutter run
    ```

5.  **Login Credentials** (Mock Auth):
    *   **Email**: `admin@azodha.com`
    *   **Password**: `password123`

---

## 🧠 BLoC Pattern Implementation

The application uses `flutter_bloc` to strictly separate the **Business Logic (BLoC)** from the **UI (Presentation)**.

*   **Events**: Every user interaction is an event (e.g., `LoadTasks`, `AddTask`, `SearchTasks`).
*   **States**: The UI only renders based on the current state (e.g., `TaskLoading`, `TaskLoaded`, `TaskError`).
*   **Predictability**: The flow is unidirectional (Event -> BLoC -> State -> UI).
*   **Optimistic UI**: For actions like "Checking a checkbox", the BLoC updates the `TaskLoaded` state immediately to provide instant feedback, while performing the API call asynchronously in the background.

---

## 🌐 Offline Support Strategy

Offline capabilities are central to this application's design:

1.  **Local First / Hybrid Approach**:
    *   The app uses **Hive** (a fast NoSQL database) as the local cache.
    *   **Online**: Data is fetched from the API, displayed, and simultaneously saved to Hive.
    *   **Offline**: The app automatically detects lack of connectivity (using `internet_connection_checker_plus`) and transparently serves data from Hive.

2.  **Creation While Offline**:
    *   New tasks created while offline are assigned temporary IDs and stored locally.
    *   These tasks appear instantly in the list, ensuring the user flow is never blocked by network status.

---

## 🚧 Challenges & Solutions

### Challenge 1: Stateless Mock API
*   **Issue**: `JSONPlaceholder` mimics a real API but does not actually save data. A standard "Refresh" would wipe out any new tasks the user added, confusing the user.
*   **Solution**: Implemented a **"Smart Merge"** strategy in the Repository. When refreshing, the app fetches server data but actively preserves any locally-created tasks (identified by custom IDs), creating the illusion of a fully persistent backend.

### Challenge 2: Order Jumping on Refresh
*   **Issue**: Local database (Hive) returns items in insertion order, while the expected UI behavior is "Newest First". This caused tasks to jump positions when switching between Offline/Online modes.
*   **Solution**: Enforced a `reversed` sort order logic in the Repository's caching layer to ensure consistent "Newest First" sorting regardless of the data source.

---

## 💭 Design Decisions & Assumptions

*   **Assumption**: The "Bonus Login" feature is for demonstration. I assumed a simple `SharedPreferences` boolean flag is sufficient for session persistence rather than a full token-based auth system.
*   **Decision (Strict Layering)**: I accepted the boilerplate overhead of separating `TaskModel` (Data Layer) from `Task` (Domain Layer). This ensures that if we switch from JSON to GraphQL or Hive to SQLite, the entire UI and Domain logic remains untouched.
*   **Decision (Swipe to Delete)**: I implemented "Swipe to Delete" with a confirmation dialog as it provides a more modern mobile UX compared to a simple delete button.

---

## 🛠 Tech Stack

*   **Language**: Dart 3.x
*   **Framework**: Flutter 3.x
*   **State Management**: `flutter_bloc` (Separation of UI and Logic).
*   **Architecture**: Clean Architecture (Presentation <- Domain <- Data).
*   **Networking**: `http` + `internet_connection_checker_plus`.
*   **Local Storage**: `hive` + `hive_flutter` (Tasks), `shared_preferences` (Auth/Theme).
*   **Theming**: Light/Dark mode support.

---

## 🏗 Architecture Logic

The project is divided into three independent layers:

### 1. Presentation Layer (`lib/presentation`, `lib/blocs`)
*   **Widgets**: Dumb components that only render the UI (`TaskItem`, `LoginScreen`).
*   **BLoC**: Holds the state (e.g., `TaskLoaded`). It receives events (`LoadTasks`) and emits new states. **It contains NO API logic.**

### 2. Domain Layer (`lib/domain`)
*   **Entities**: Pure Dart classes (`Task`) without JSON serialization logic.
*   **Repositories (Interfaces)**: Abstract definitions of what data operations exist (`getTasks()`).
*   **Dependency Rule**: This layer depends on *nothing*.

### 3. Data Layer (`lib/data`)
*   **Models**: DTOs (`TaskModel`) that handle JSON/Hive conversion.
*   **Data Sources**:
    *   `RemoteDataSource`: Talks to `jsonplaceholder`.
    *   `LocalDataSource`: Talks to Hive Box.
*   **Repositories (Impl)**: The "Brain" that decides source of truth.
    *   *Logic*: "If Online -> Fetch Remote -> Merge with Local -> Save to Cache -> Return. If Offline -> Return Cache."

---

## 📂 Folder Structure

```
lib/
├── blocs/          # State Management (Auth, Task)
├── core/           # Constants (Colors, Dimensions, Errors)
├── data/           # Repositories Impl, Models, Datasources
├── domain/         # Entities, Repository Interfaces
├── presentation/   # Screens, Widgets
└── main.dart       # Entry point & Dependency Injection
```
