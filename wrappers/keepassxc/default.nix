{
  inputs,
  pkgs,
  ...
}:
let
  keepassxcWrapper = pkgs.callPackage ./module.nix { inherit inputs; };
in
(keepassxcWrapper.apply {
  pkgs = pkgs;
  settings = {
    # general settings (no prefix in Config.cpp)
    General = {
      SingleInstance = true;
      RememberLastDatabases = true;
      NumberOfRememberedLastDatabases = 5;
      RememberLastKeyFiles = false;
      OpenPreviousDatabasesOnStartup = true;
      AutoSaveAfterEveryChange = true;
      AutoReloadOnChange = true;
      AutoSaveOnExit = true;
      AutoSaveNonDataChanges = true;
      BackupBeforeSave = true;
      BackupFilePathPattern = "{DB_FILENAME}.old.kdbx";
      UseAtomicSaves = true;
      UseDirectWriteSaves = false;
      SearchLimitGroup = false;
      MinimizeOnOpenUrl = false;
      OpenURLOnDoubleClick = true;
      URLDoubleClickAction = 0;
      HideWindowOnCopy = false;
      MinimizeOnCopy = true;
      AutoGeneratePasswordForNewEntries = false;
      MinimizeAfterUnlock = true;
      DropToBackgroundOnCopy = false;
      UseGroupIconOnEntryCreation = true;
      AutoTypeEntryTitleMatch = true;
      AutoTypeEntryURLMatch = true;
      AutoTypeDelay = 25;
      AutoTypeStartDelay = 500;
      AutoTypeHideExpiredEntry = false;
      AutoTypeDialogSortColumn = 0;
      AutoTypeDialogSortOrder = 0;
      GlobalAutoTypeKey = 0;
      GlobalAutoTypeModifiers = 0;
      GlobalAutoTypeRetypeTime = 15;
      FaviconDownloadTimeout = 10;
      UpdateCheckMessageShown = false;
      DefaultDatabaseFileName = "";
    };

    # gui settings
    GUI = {
      Language = "system";
      HideMenubar = false;
      HideToolbar = false;
      MovableToolbar = false;
      HideGroupPanel = false;
      HidePreviewPanel = false;
      AlwaysOnTop = false;
      ToolButtonStyle = 0; # icon only
      LaunchAtStartup = false;
      ShowTrayIcon = true;
      TrayIconAppearance = "monochrome-light";
      MinimizeToTray = true;
      MinimizeOnStartup = true;
      MinimizeOnClose = true;
      HideUsernames = false;
      HidePasswords = true;
      ColorPasswords = true;
      MonospaceNotes = true;
      ApplicationTheme = "dark";
      CompactMode = true;
      CheckForUpdates = true;
      CheckForUpdatesIncludeBetas = false;
      SearchWaitForEnter = false;
      ShowExpiredEntriesOnDatabaseUnlock = true;
      ShowExpiredEntriesOnDatabaseUnlockOffsetDays = 3;
      AutoTypeSelectDialogSize = "600x250";
    };

    # security settings
    Security = {
      ClearClipboard = false;
      ClearClipboardTimeout = 30;
      ClearSearch = true;
      ClearSearchTimeout = 5;
      HideNotes = false;
      LockDatabaseIdle = false;
      LockDatabaseIdleSeconds = 900;
      LockDatabaseMinimize = false;
      LockDatabaseScreenLock = true;
      LockDatabaseOnUserSwitch = true;
      RelockAutoType = false;
      PasswordsHidden = true;
      PasswordEmptyPlaceholder = true;
      HidePasswordPreviewPanel = true;
      HideTotpPreviewPanel = false;
      AutoTypeAsk = true;
      AutoTypeSkipMainWindowConfirmation = false;
      IconDownloadFallback = false;
      NoConfirmMoveEntryToRecycleBin = true;
      EnableCopyOnDoubleClick = true;
      QuickUnlock = true;
      DatabasePasswordMinimumQuality = 0;
    };

    # browser integration
    Browser = {
      Enabled = true;
      ShowNotification = true;
      BestMatchOnly = false;
      UnlockDatabase = true;
      MatchUrlScheme = true;
      SupportBrowserProxy = true;
      UseCustomProxy = false;
      CustomProxyLocation = "";
      UpdateBinaryPath = true;
      AllowGetDatabaseEntriesRequest = false;
      AllowExpiredCredentials = false;
      AlwaysAllowAccess = false;
      AlwaysAllowUpdate = false;
      HttpAuthPermission = false;
      SearchInAllDatabases = false;
      SupportKphFields = true;
      NoMigrationPrompt = false;
      AllowLocalhostWithPasskeys = false;
    };
    # ssh agent
    SSHAgent = {
      Enabled = false;
      UseOpenSSH = false;
      UsePageant = true;
    };
    # fdo secrets
    FdoSecrets = {
      Enabled = false;
      ShowNotification = true;
      ConfirmDeleteItem = true;
      ConfirmAccessItem = true;
      UnlockBeforeSearch = true;
    };
    # keeshare
    KeeShare = {
      QuietSuccess = false;
    };
    # password generator
    PasswordGenerator = {
      LowerCase = true;
      UpperCase = true;
      Numbers = true;
      EASCII = false;
      AdvancedMode = false;
      SpecialChars = true;
      Braces = false;
      Punctuation = false;
      Quotes = false;
      Dashes = false;
      Math = false;
      Logograms = true;
      AdditionalChars = "";
      ExcludedChars = "";
      ExcludeAlike = true;
      EnsureEvery = true;
      Length = 20;
      WordCount = 3;
      WordSeparator = " ";
      WordList = "eff_large.wordlist";
      WordCase = 0;
      Type = 0;
    };
    # messages
    Messages = {
      NoLegacyKeyFileWarning = false;
    };
  };
}).wrapper
