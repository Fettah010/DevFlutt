# Preferences module

Select with `ftemplate create --name MyApp --org com.example --module preferences`.

The module wraps `SharedPreferencesAsync` behind `PreferencesStore` and includes an in-memory
implementation for tests. It supports primitive values and removal/clear operations. Use it
for non-sensitive settings such as display preferences. Tokens, passwords, payment details,
and other secrets belong in `secure-storage`.

The module adds `shared_preferences` at runtime and no Android permissions. It is not selected
by any preset. Run the generated `preferences_store_test.dart` with `flutter test`.
