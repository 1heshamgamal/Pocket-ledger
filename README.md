# Pocket Ledger (دفتر الجيب)

A simple personal finance app designed to help users track their daily expenses, debts (both owed and owing), and view clear monthly financial reports. The app works offline and can later support cloud sync using Firebase.

## Features

### Transaction Entry
- Add new financial operations
- Track expenses, debts you owe, and debts owed to you
- Enter amount, description, and date

### Monthly Report
- View monthly financial summary
- See total expenses, debts you owe, and debts owed to you
- Calculate net balance
- Visualize breakdown with a pie chart

### Debt Management
- View and manage all recorded debts
- Track status (paid/unpaid)
- Mark debts as paid
- Edit or delete debts

### Settings
- Change language (Arabic/English)
- Change currency (USD, SAR, EGP)
- Enable/Disable dark mode

## Technical Details

### Built With
- Flutter
- SQLite for local storage
- Provider for state management
- Internationalization support for Arabic and English

### Project Structure
- `lib/models/`: Data models
- `lib/screens/`: Main app screens
- `lib/services/`: Database and settings services
- `lib/widgets/`: Reusable UI components
- `lib/utils/`: Utility functions and constants
- `lib/l10n/`: Localization files

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or VS Code with Flutter extensions

### Installation
1. Clone the repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Future Enhancements
- Export monthly reports to PDF
- Smart reminders for unpaid debts
- Sync with Firebase
- Backup and restore functionality
- Lock app with PIN or fingerprint