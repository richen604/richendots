{ pkgs, ... }:
/*
  todo: firefox: clean up and consolidate variables
  todo: firefox: font consolidation

  Mostly inspired by textfox, pruned a bunch of stuff I didn't like or need.
  give them a star here https://github.com/adriankarlen/textfox
*/
let
  policies = builtins.fromJSON (builtins.readFile ./policies.json);

  # shamelessly replacing ascii art
  text = ''
               __            __                             ______                    
               /  |          /  |                           /      \                   
       ______  $$/   _______ $$ |____    ______   _______  /$$$$$$  |______   __    __ 
      /      \ /  | /       |$$      \  /      \ /       \ $$ |_ $$//      \ /  \  /  |
    /$$$$$$  |$$ |/$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$  |$$   |  /$$$$$$  |$$  \/$$/ 
    $$ |  $$/ $$ |$$ |      $$ |  $$ |$$    $$ |$$ |  $$ |$$$$/   $$ |  $$ | $$  $$<  
    $$ |      $$ |$$ \_____ $$ |  $$ |$$$$$$$$/ $$ |  $$ |$$ |    $$ \__$$ | /$$$$  \ 
    $$ |      $$ |$$       |$$ |  $$ |$$       |$$ |  $$ |$$ |    $$    $$/ /$$/ $$  |
    $$/       $$/  $$$$$$$/ $$/   $$/  $$$$$$$/ $$/   $$/ $$/      $$$$$$/  $$/   $$/ 
                                                                                      
                                                                                      
                                                                                      
  '';

  processedText = builtins.replaceStrings [ "\n" "\\" ] [ "\\A" "\\\\" ] text;

  chromeFolder = pkgs.runCommand "firefox-chrome" { } ''
    mkdir -p $out/
    # can copy other files relative to this folder
    cp ${
      pkgs.replaceVars ./userChrome.css {
        "textfox-logo" = processedText;
      }
    } $out/userChrome.css
  '';
in
pkgs.wrapFirefox pkgs.firefox-unwrapped {
  extraPolicies = policies;

  extraPrefs = ''
    // Fill SVG Color
    pref("svg.context-properties.content.enabled", true);
    // CSS's `:has()` selector 
    pref("layout.css.has-selector.enabled", true);
    pref("browser.display.use_document_fonts", 0);

    // Auto-load userChrome.css
    try {
      let sss = Components.classes["@mozilla.org/content/style-sheet-service;1"]
        .getService(Components.interfaces.nsIStyleSheetService);
      let uri = Services.io.newURI("file://${chromeFolder}/userChrome.css", null, null);
      if (!sss.sheetRegistered(uri, sss.USER_SHEET)) {
        sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
      }
    } catch(ex) {
      Components.utils.reportError("Failed to load userChrome.css: " + ex.message);
    }
  '';
}
