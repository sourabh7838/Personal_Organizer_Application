# Task Management Application

## Overview
This task management application is a sophisticated mobile solution developed using Flutter, designed to help users efficiently organize and manage their daily tasks. The application implements a comprehensive task management system with features like task categorization, priority levels, due dates with notifications, and an intuitive user interface.

## Core Features Implemented

### Task Management
- Create, edit, and delete tasks
- Set task priorities (High, Medium, Low)
- Add detailed descriptions to tasks
- Mark tasks as completed/incomplete
- Star important tasks for quick access

### Task Organization
- Organize tasks into customizable lists
- Create categories for better task grouping
- Filter tasks by various criteria
- Search functionality for quick task location

### Time Management
- Set due dates and times for tasks
- Receive notifications for upcoming tasks
- 30-minute early reminder notifications
- Visual indicators for overdue tasks

### User Interface
- Clean and intuitive Material Design interface
- Responsive layout adapting to different screen sizes
- Visual priority indicators with color coding
- Smooth animations and transitions
- Dark/Light theme support

### Task Interaction
- Swipe-to-delete functionality
- Quick actions through context menus
- Batch task management capabilities
- Real-time updates across the app

## Technology Stack

### Core Technologies
- **Flutter (Latest Version)**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management solution

### Key Packages
- `flutter_local_notifications`: For task reminders and notifications
- `provider`: For state management
- `hive` & `hive_flutter`: For local data persistence
- `intl`: For date and time formatting
- `timezone`: For handling different time zones
- `uuid`: For unique identifier generation

## Project Structure
```
lib/
├── core/
│   ├── services/
│   │   └── notification_service.dart    # Handles local notifications
│   └── utils/
│       └── hive_boxes.dart             # Hive database configuration
│
├── features/
│   └── tasks/
│       ├── models/
│       │   ├── task.dart               # Task data model
│       │   ├── task.g.dart             # Generated Hive adapters
│       │   ├── task_list.dart          # TaskList data model
│       │   └── task_list.g.dart        # Generated Hive adapters
│       │
│       ├── providers/
│       │   └── task_provider.dart      # State management for tasks
│       │
│       ├── screens/
│       │   ├── add_edit_task_screen.dart    # Task creation/editing
│       │   ├── task_list_screen.dart        # Main task list view
│       │   └── task_details_screen.dart     # Task details view
│       │
│       └── widgets/
│           ├── task_tile.dart          # Individual task item
│           ├── task_list_view.dart     # List of tasks
│           └── filtered_tasks_view.dart # Filtered task views
│
└── main.dart                           # Application entry point
```

### Directory Structure Explanation

#### Core
- **services**: Contains core application services
  - `notification_service.dart`: Manages all notification-related functionality
- **utils**: Utility classes and helper functions
  - `hive_boxes.dart`: Hive database configuration and box names

#### Features
The application follows a feature-first architecture pattern:

##### Tasks Feature
- **models**: Data models and their Hive adapters
  - `task.dart`: Core task model with all properties
  - `task_list.dart`: Model for organizing tasks into lists
  
- **providers**: State management
  - `task_provider.dart`: Manages task state and operations
  
- **screens**: Main application screens
  - `add_edit_task_screen.dart`: Task creation and editing interface
  - `task_list_screen.dart`: Main task list view
  - `task_details_screen.dart`: Detailed task view
  
- **widgets**: Reusable UI components
  - `task_tile.dart`: Individual task display widget
  - `task_list_view.dart`: List view for tasks
  - `filtered_tasks_view.dart`: Filtered task views

### Architecture Patterns
- Feature-first architecture for better scalability
- Provider pattern for state management
- Repository pattern for data operations
- Service pattern for core functionalities

## Setup Instructions

### Prerequisites
1. Flutter SDK (Latest Version)
2. Dart SDK (Latest Version)
3. Android Studio / VS Code with Flutter extensions
4. iOS development setup (for Mac users)
5. Git

### Installation Steps
1. Clone the repository:
   ```bash
   git clone [repository-url]
   ```

2. Navigate to the project directory:
   ```bash
   cd challenge_1_group_2
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the code generation for Hive:
   ```bash
   flutter pub run build_runner build
   ```

## Running the Application

### Development Environment
1. Open a simulator/emulator or connect a physical device
2. Run the application:
   ```bash
   flutter run
   ```

### Building for Production
- For Android:
  ```bash
  flutter build apk --release
  ```
- For iOS:
  ```bash
  flutter build ios --release
  ```

## Screenshots and Features

### 1. Home Screen

<img width="156" alt="image" src="https://github.com/user-attachments/assets/02e02e41-29da-41e9-926d-7e0ee2340f76" />

<img width="156" alt="image" src="https://github.com/user-attachments/assets/1ce4afbf-7b78-4a7b-9f24-544cf1bc65e4" />

<img width="158" alt="image" src="https://github.com/user-attachments/assets/8af158fc-d007-45f1-b16e-be47dd0224b3" />

- Displays all tasks organized by lists
- Quick access to starred tasks
- Bottom navigation for different views
- Floating action button for adding new tasks

### 2. Task Creation/Editing

<img width="164" alt="image" src="https://github.com/user-attachments/assets/ff7e0311-008e-4155-b0a5-32a867d911be" />

<img width="160" alt="image" src="https://github.com/user-attachments/assets/2bc1734b-a11f-4f5e-98bb-1e72996e4eea" />

<img width="169" alt="image" src="https://github.com/user-attachments/assets/f6e330d1-4245-475e-a985-8c998674880e" />

<img width="172" alt="image" src="https://github.com/user-attachments/assets/83771dd8-dc4e-407d-b3d1-cafd60bc935b" />

- Form for creating/editing tasks
- Priority selection with color coding
- Due date and time picker
- Description field for detailed notes

### 3. Task List View

<img width="167" alt="image" src="https://github.com/user-attachments/assets/edaa0136-2225-4127-966e-14715f5d97a0" />

<img width="165" alt="image" src="https://github.com/user-attachments/assets/10d5b854-44f0-4d4b-9a91-bada4b8a8fe8" />

<img width="164" alt="image" src="https://github.com/user-attachments/assets/022a3885-35e8-430e-a56f-aa45ad4299c1" />

- Tasks grouped by completion status
- Visual indicators for priority levels
- Due date/time display with clock icon
- Swipe actions for quick task management
- Task filtering by category
- Category creation and management
- Hierarchical view of task categories

### 4. Notification System and Restore Delete tasks
<img width="163" alt="image" src="https://github.com/user-attachments/assets/052fde7d-88f8-48dc-aadb-0e3bf252c0b7" />

<img width="166" alt="image" src="https://github.com/user-attachments/assets/3d30c9d0-7688-4552-91fc-404bccc43019" />

<img width="215" alt="image" src="https://github.com/user-attachments/assets/c60b34d8-463c-4381-b627-f35c7485beae" />

<img width="215" alt="image" src="https://github.com/user-attachments/assets/80bda064-57d4-4fb5-890a-44dcc9b6ae7e" />

- Notification preferences setup
- Scheduled notification examples
- Early reminder configuration
- Custom notification actions
- Trash screen with restore button
-	Permanently remove all deleted tasks.

## GitHub Repository
https://github.com/sourabh7838/Personal_Organizer_Application

## Additional Notes
- The application follows Material Design guidelines
- Implements best practices for Flutter development
- Features responsive design for various screen sizes
- Includes comprehensive error handling
- Supports both iOS and Android platforms

## Future Enhancements
- Cloud synchronization
- Task sharing capabilities
- Advanced recurring tasks
- Statistical analysis and reports
- Custom theme creation

