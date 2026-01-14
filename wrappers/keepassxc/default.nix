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
    Browser = {
      AllowExpiredCredentials = false;
      AlwaysAllowAccess = false;
      BrowserType = 0;
      CustomExtensionID = "";
      CustomProxyLocation = "";
      Enabled = true;
      NoMigrationPrompt = false;
      SearchInAllDatabases = false;
      UpdateBinaryPath = true;
      UseCustomProxy = false;
    };
    GUI = {
      ApplicationTheme = "dark";
      ColorPasswords = true;
      CompactMode = true;
      HideUsernames = false;
      MinimizeOnClose = true;
      MinimizeOnStartup = true;
      MonospaceNotes = true;
      ShowTrayIcon = true;
      TrayIconAppearance = "monochrome-light";
    };
    General = {
      AutoReloadOnChange = true;
      AutoSaveAfterEveryChange = true;
      BackupBeforeSave = true;
      ConfigVersion = 2;
      MinimizeAfterUnlock = true;
      MinimizeOnCopy = true;
      MinimizeOnStartup = true;
      MinimizeToTray = true;
      RememberLastDatabases = true;
      RememberLastKeyFiles = false;
      ShowTrayIcon = true;
      SingleInstance = true;
      UseAtomicSaves = true;
      UseGroupIconOnEntryCreation = true;
    };
    PasswordGenerator = {
      AdditionalChars = "";
      ExcludedChars = "";
      Length = 20;
      Logograms = true;
      SpecialChars = true;
      Type = 0;
      WordCount = 3;
    };
    Security = {
      ClearClipboardTimeout = 30;
      ClearSearch = true;
      ClearSearchTimeout = 5;
      EnableCopyOnDoubleClick = true;
      HidePasswordPreviewPanel = true;
      LockDatabaseIdle = false;
      LockDatabaseScreenLock = true;
      PasswordEmptyPlaceholder = true;
      QuickUnlock = true;
    };
  };
}).wrapper
