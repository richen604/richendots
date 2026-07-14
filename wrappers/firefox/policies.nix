{
  Preferences = {
    "privacy.globalprivacycontrol.enabled" = true;
    "media.eme.enabled" = true;
    "browser.aboutConfig.showWarning" = false;
    "browser.warnOnQuitShortcut" = false;
    "browser.link.open_newwindow.override.external" = 7;
    "media.webspeech.synth.dont_notify_on_error" = true;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.unitConversion.enabled" = true;
    "browser.urlbar.trimHttps" = true;
    "browser.urlbar.suggest.searches" = true;
    "browser.toolbars.bookmarks.visibility" = "never";
    "services.sync.engine.tabs" = false;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.hardware-video-decoding.force-enabled" = true;
    "widget.dmabuf.force-enabled" = true;
    "layers.acceleration.force-enabled" = true;
    "gfx.webrender.all" = true;
    "browser.in-content.dark-mode" = true;
    "ui.systemUsesDarkTheme" = true;
    "widget.use-xdg-desktop-portal.file-picker" = 1;
    "extensions.autoDisableScopes" = 0;
    "extensions.update.enabled" = false;

    # Low-breakage privacy baseline. Avoid RFP, WebGL/WebRTC disablement, and
    # cookie clearing so normal sites and persisted logins keep working.
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "data:,";
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.usage.uploadEnabled" = false;
    "toolkit.coverage.opt-out" = true;
    "toolkit.coverage.enabled" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
    "app.shield.optoutstudies.enabled" = false;
    "browser.discovery.enabled" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "dom.private-attribution.submission.enabled" = false;
    "network.prefetch-next" = false;
    "network.dns.disablePrefetch" = true;
    "network.dns.disablePrefetchFromHTTPS" = true;
    "network.http.speculative-parallel-limit" = 0;
    "browser.urlbar.speculativeConnect.enabled" = false;
    "browser.places.speculativeConnect.enabled" = false;
    "network.captive-portal-service.enabled" = false;
    "network.connectivity-service.enabled" = false;
    "dom.security.https_only_mode" = true;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.IDN_show_punycode" = true;
    "pdfjs.enableScripting" = false;

    # Defensive prefs for Firefox AI/ML surfaces not covered by older policies.
    "browser.ml.enable" = false;
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.menu" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnabled" = false;

    # Future no-persisted-logins mode. Enable this block when browser sessions
    # should stop keeping site cookies/storage and form state across restarts.
    # "privacy.sanitize.sanitizeOnShutdown" = true;
    # "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
    # "privacy.clearOnShutdown_v2.cache" = true;
    # "privacy.clearOnShutdown_v2.formdata" = true;
    # "privacy.clearSiteData.cookiesAndStorage" = true;
  };

  DontCheckDefaultBrowser = true;
  DisableFirefoxScreenshots = true;
  DisableFirefoxStudies = true;
  DisableTelemetry = true;
  DisplayBookmarksToolbar = "never";
  DisplayMenuBar = "never";
  OverrideFirstRunPage = "";
  PictureInPicture.Enabled = false;
  GenerativeAI.Enabled = false;
  AIControls = {
    Default = {
      Value = "blocked";
      Locked = true;
    };
    Translations = {
      Value = "blocked";
      Locked = true;
    };
    PDFAltText = {
      Value = "blocked";
      Locked = true;
    };
    SmartTabGroups = {
      Value = "blocked";
      Locked = true;
    };
    LinkPreviewKeyPoints = {
      Value = "blocked";
      Locked = true;
    };
    SidebarChatbot = {
      Value = "blocked";
      Locked = true;
    };
    SmartWindow = {
      Value = "blocked";
      Locked = true;
    };
  };
  PromptForDownloadLocation = false;
  HardwareAcceleration = true;
  TranslateEnabled = true;
  Homepage.StartPage = "previous-session";
  UserMessaging = {
    SkipOnboarding = true;
    UrlbarInterventions = false;
  };
  FirefoxSuggest = {
    ImproveSuggest = false;
    SponsoredSuggestions = false;
    WebSuggestions = false;
  };
  EnableTrackingProtection = {
    Cryptomining = true;
    Fingerprinting = true;
    EmailTracking = true;
    Value = true;
  };
  FirefoxHome = {
    Search = true;
    TopSites = false;
    SponsoredTopSites = false;
    Highlights = false;
    Pocket = false;
    SponsoredPocket = false;
    Stories = false;
    SponsoredStories = false;
    Snippets = false;
  };
  SearchEngines = {
    Remove = [
      "DuckDuckGo"
      "Bing"
      "eBay"
      "Amazon.com"
      "Wikipedia (en)"
      "Google"
      "Perplexity"
    ];
    Default = "Rebang";
    Add = [
      {
        Name = "SearXNG";
        Alias = "sx";
        IconURL = "https://search.cedar.richen.sh/favicon.ico";
        URLTemplate = "https://search.cedar.richen.sh/search?q={searchTerms}";
      }
      {
        Name = "Rebang";
        Alias = "rb";
        IconURL = "https://www.rebang.online/favicon.icon";
        URLTemplate = "https://www.rebang.online/?q={searchTerms}";
      }
    ];
  };
  ExtensionSettings = {
    # Block extensions that used to be force-installed so profile copies do not linger.
    "jid1-BoFifL9Vbdl2zQ@jetpack" = {
      installation_mode = "blocked";
    };
    "clipper@obsidian.md" = {
      installation_mode = "blocked";
    };
    "{2662ff67-b302-4363-95f3-b050218bd72c}" = {
      installation_mode = "blocked";
    };
    "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
      installation_mode = "blocked";
    };
    "vimium-c@gdh1995.cn" = {
      installation_mode = "blocked";
    };

    "addon@darkreader.org" = {
      install_url = "https://addons.mozilla.org/en-CA/firefox/downloads/latest/darkreader/latest.xpi";
      installation_mode = "force_installed";
    };
    "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = {
      install_url = "https://addons.mozilla.org/en-CA/firefox/downloads/latest/auto-tab-discard/latest.xpi";
      installation_mode = "force_installed";
    };
    "{74145f27-f039-47ce-a470-a662b129930a}" = {
      install_url = "https://addons.mozilla.org/en-CA/firefox/downloads/latest/clearurls/latest.xpi";
      installation_mode = "force_installed";
    };
    "keepassxc-browser@keepassxc.org" = {
      install_url = "https://addons.mozilla.org/en-CA/firefox/downloads/latest/keepassxc-browser/latest.xpi";
      installation_mode = "force_installed";
    };
    "sponsorBlocker@ajay.app" = {
      install_url = "https://addons.mozilla.org/en-CA/firefox/downloads/latest/sponsorblock/latest.xpi";
      installation_mode = "force_installed";
    };
    "uBlock0@raymondhill.net" = {
      install_url = "https://addons.mozilla.org/en-CA/firefox/downloads/latest/ublock-origin/latest.xpi";
      installation_mode = "force_installed";
    };
  };
}
