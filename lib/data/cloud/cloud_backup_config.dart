/// Google OAuth configuration for Drive backups.
///
/// Create these in Google Cloud Console (see the setup notes in the PR/chat):
///  1. An **Android** OAuth client (package `com.lykon.holdstrong` + SHA-1).
///  2. A **Web application** OAuth client — paste ITS client ID below.
///
/// The Web client ID is public (it ships in every app that uses it), so it is
/// fine to commit. Leave empty until you have created it; the Settings screen
/// will say the feature is not configured.
class CloudBackupConfig {
  CloudBackupConfig._();

  static const String webClientId =
      '692837421154-ho5tloptl26787llmencjpoci99k659f.apps.googleusercontent.com';

  static bool get isConfigured => webClientId.isNotEmpty;

  /// Name of the folder created in the root of the user's Drive.
  static const String rootFolderName = 'HoldStrong Backups';
  static const String dailyFolderName = 'daily';
  static const String monthlyFolderName = 'monthly';
  static const String csvFileName = 'transactions.csv';
  static const String fundAccountsCsvFileName = 'fund_accounts.csv';
  static const String transfersCsvFileName = 'transfers.csv';

  /// How many dated JSON backups to keep in the daily folder.
  static const int maxDailyBackups = 10;
}
