{ pkgs, ... }:
let
  version = "0.1.63a";
  runtimeSubdir = "lib/glide-browser-${version}";
  policies = import ../firefox/policies.nix;
  policiesJson = pkgs.writeText "glide-policies.json" (builtins.toJSON { inherit policies; });

  # FirefoxPWA's native connector and patch assets, without its bundled Firefox runtime.
  firefoxpwaConnectorOnly = pkgs.firefoxpwa-unwrapped.overrideAttrs (old: {
    pname = "firefoxpwa-connector";
    postInstall = ''
      mkdir -p $out/share/firefoxpwa
      cp -r userchrome $out/share/firefoxpwa
      substituteInPlace $out/share/firefoxpwa/userchrome/profile/chrome/pwa/boot.sys.mjs \
        --replace-fail "if (options.openerWindow && options.openerWindow.gFFPWASiteConfig && !options.args)" \
          "if (options?.openerWindow && options.openerWindow.gFFPWASiteConfig && !options.args)"
      substituteInPlace $out/share/firefoxpwa/userchrome/profile/chrome/pwa/boot.sys.mjs \
        --replace-fail "Services.prefs.getIntPref('firefoxpwa.launchType', 0)" \
          "Services.prefs.getIntPref('firefoxpwa.launchType', 3)"
      grep -Fq "options?.openerWindow" $out/share/firefoxpwa/userchrome/profile/chrome/pwa/boot.sys.mjs
      grep -Fq "getIntPref('firefoxpwa.launchType', 3)" $out/share/firefoxpwa/userchrome/profile/chrome/pwa/boot.sys.mjs

      sed -i "s!/usr/libexec!$out/bin!" manifests/linux.json
      install -Dm644 manifests/linux.json $out/lib/mozilla/native-messaging-hosts/firefoxpwa.json

      wrapProgram $out/bin/firefoxpwa \
        --prefix FFPWA_SYSDATA : "$out/share/firefoxpwa"

      wrapProgram $out/bin/firefoxpwa-connector \
        --prefix FFPWA_SYSDATA : "$out/share/firefoxpwa"
    '';
    passthru = (old.passthru or { }) // {
      runtimeIncluded = false;
    };
  });
  keepassxcNativeMessagingManifest = pkgs.writeText "org.keepassxc.keepassxc_browser.json" (
    builtins.toJSON {
      name = "org.keepassxc.keepassxc_browser";
      description = "KeePassXC integration with native messaging support";
      path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
      type = "stdio";
      allowed_extensions = [ "keepassxc-browser@keepassxc.org" ];
    }
  );
  firefoxpwaNativeMessagingManifest = pkgs.writeText "firefoxpwa.json" (
    builtins.toJSON {
      name = "firefoxpwa";
      description = "The native part of the PWAsForFirefox project";
      path = "${firefoxpwaConnectorOnly}/bin/firefoxpwa-connector";
      type = "stdio";
      allowed_extensions = [ "firefoxpwa@filips.si" ];
    }
  );
  text = ''
             __            __                             ______                    
             /  |          /  |                           /      \                   
     ______  $$/   _______ $$ |____    ______   _______  /$$$$$$  |______   __    __ 
    /      \ /  | /       |$$      \  /      \ /       \ $$ |_ $$//      \ /  \  /  |
    /$$$$$$  |$$ |/$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$  |$$   |  /$$$$$$  |$$  \/$$/ 
    $$ |  $$/ $$ |$$ |      $$ |  $$ |$$    $$ |$$ |  $$ |$$$$/   $$ |  $$ | $$  $$<  
    $$ |      $$ |$$ \_____ $$ |  $$ |$$$$$$$$/ $$ |  $$ |$$ |    $$ \__$$ | /$$$$  \ 
    $$/       $$/  $$$$$$$/ $$/   $$/  $$$$$$$/ $$/   $$/ $$/      $$$$$$/  $$/   $$/ 
  '';
  chromeCss = pkgs.replaceVars ./userChrome.css {
    "textfox-logo" = builtins.replaceStrings [ "\n" "\\" ] [ "\\A" "\\\\" ] text;
  };
  contentCss = pkgs.replaceVars ./userContent.css {
    "textfox-logo" = builtins.replaceStrings [ "\n" "\\" ] [ "\\A" "\\\\" ] text;
  };
  graphicsLibraryPath = pkgs.lib.makeLibraryPath [
    pkgs.ffmpeg
    pkgs.libgbm
    pkgs.libglvnd
    pkgs.mesa
    pkgs.vulkan-loader
    pkgs.libva.out
    pkgs.pipewire
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "glide-browser";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
    hash = "sha256-idHArAa57FADdmhCI/5vK47SEd0dlz0diH4DRDmKDmE=";
  };

  sourceRoot = "glide";

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
    pkgs.patchelfUnstable
    pkgs.wrapGAppsHook3
  ];

  buildInputs = [
    pkgs.adwaita-icon-theme
    pkgs.alsa-lib
    pkgs.dbus-glib
    pkgs.gtk3
    pkgs.libXtst
  ];

  runtimeDependencies = [
    pkgs.curl
    pkgs.ffmpeg
    pkgs.libgbm
    pkgs.libglvnd
    pkgs.libva.out
    pkgs.mesa
    pkgs.pciutils
    pkgs.vulkan-loader
  ];

  appendRunpaths = [
    "${pkgs.pipewire}/lib"
  ];
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    glide_runtime=$out/${runtimeSubdir}

    mkdir -p "$glide_runtime" $out/bin
    cp -r . "$glide_runtime"
    mv "$glide_runtime/glide" "$glide_runtime/glide-unwrapped"
    ln -s "$glide_runtime/glide-unwrapped" "$glide_runtime/firefox"
    ln -s "$glide_runtime/glide-unwrapped" $out/bin/glide-unwrapped

    # FirefoxPWA-generated desktop entries call `firefoxpwa`, so expose the
    # connector CLI through the Glide package without adding a second runtime.
    cat > $out/bin/firefoxpwa <<EOF
    #!${pkgs.runtimeShell}
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_DISABLE_RDD_SANDBOX="\''${MOZ_DISABLE_RDD_SANDBOX:-1}"
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${graphicsLibraryPath}:\''${LD_LIBRARY_PATH:-}"
    if [ -e /run/opengl-driver/lib/dri/nvidia_drv_video.so ]; then
      export LIBVA_DRIVER_NAME="\''${LIBVA_DRIVER_NAME:-nvidia}"
      export LIBVA_DRIVERS_PATH="/run/opengl-driver/lib/dri:\''${LIBVA_DRIVERS_PATH:-}"
      export NVD_BACKEND="\''${NVD_BACKEND:-direct}"
    fi
    if [ "\''${1:-}" = site ] && [ "\''${2:-}" = launch ] && [ "\''${4:-}" = --protocol ] && [ "\''${5:-}" = %u ]; then
      site_id="\$3"
      config="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/config.json"
      fallback_url="\$(${pkgs.jq}/bin/jq -er --arg site_id "\$site_id" '.sites[\$site_id] | .config.start_url // .manifest.start_url // .config.document_url' "\$config" 2>/dev/null || true)"
      if [ -n "\$fallback_url" ]; then
        set -- site launch "\$site_id" --url "\$fallback_url"
      fi
    fi
    exec ${firefoxpwaConnectorOnly}/bin/firefoxpwa "\$@"
    EOF
    chmod +x $out/bin/firefoxpwa

    ln -s ${firefoxpwaConnectorOnly}/bin/firefoxpwa-connector $out/bin/firefoxpwa-connector

    # Patch Glide's own Firefox-compatible runtime at build time. This keeps the
    # runtime immutable and avoids FirefoxPWA's normal downloaded Firefox copy.
    mkdir -p $out/share/firefoxpwa
    ln -s "$glide_runtime" $out/share/firefoxpwa/runtime
    FFPWA_SYSDATA=${firefoxpwaConnectorOnly}/share/firefoxpwa \
      FFPWA_USERDATA=$out/share/firefoxpwa \
      ${firefoxpwaConnectorOnly}/bin/.firefoxpwa-wrapped runtime patch

    test -x $out/bin/firefoxpwa
    test -x $out/bin/firefoxpwa-connector
    test -e "$glide_runtime/firefox"
    test -e "$glide_runtime/application.ini"
    test -e "$glide_runtime/_autoconfig.cfg"
    test -e "$glide_runtime/defaults/pref/autoconfig.js"

    cat > $out/bin/glide <<EOF
    #!${pkgs.runtimeShell}
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_DISABLE_RDD_SANDBOX="\''${MOZ_DISABLE_RDD_SANDBOX:-1}"
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${graphicsLibraryPath}:\''${LD_LIBRARY_PATH:-}"
    if [ -e /run/opengl-driver/lib/dri/nvidia_drv_video.so ]; then
      export LIBVA_DRIVER_NAME="\''${LIBVA_DRIVER_NAME:-nvidia}"
      export LIBVA_DRIVERS_PATH="/run/opengl-driver/lib/dri:\''${LIBVA_DRIVERS_PATH:-}"
      export NVD_BACKEND="\''${NVD_BACKEND:-direct}"
    fi
    profile="\''${XDG_CONFIG_HOME:-\$HOME/.config}/glide"
    mkdir -p "\$profile/chrome"
    ln -sf ${./glide.ts} "\$profile/glide.ts"
    ln -sf ${./tsconfig.json} "\$profile/tsconfig.json"
    ln -sf ${chromeCss} "\$profile/chrome/userChrome.css"
    ln -sf ${contentCss} "\$profile/chrome/userContent.css"
    firefoxpwa_runtime="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/runtime"
    if [ -d "\$firefoxpwa_runtime" ] && [ ! -e "\$firefoxpwa_runtime/firefox" ] && [ ! -e "\$firefoxpwa_runtime/application.ini" ]; then
      rmdir "\$firefoxpwa_runtime" 2>/dev/null || true
    fi
    if [ -L "\$firefoxpwa_runtime" ] && [ "\$(readlink "\$firefoxpwa_runtime")" != "$out/${runtimeSubdir}" ]; then
      rm "\$firefoxpwa_runtime"
    fi
    if [ ! -e "\$firefoxpwa_runtime" ]; then
      mkdir -p "\$(dirname "\$firefoxpwa_runtime")"
      ln -s $out/${runtimeSubdir} "\$firefoxpwa_runtime"
    fi
    mkdir -p "\$HOME/.glide-browser/native-messaging-hosts"
    ln -sf ${keepassxcNativeMessagingManifest} "\$HOME/.glide-browser/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
    ln -sf ${firefoxpwaNativeMessagingManifest} "\$HOME/.glide-browser/native-messaging-hosts/firefoxpwa.json"
    exec $out/${runtimeSubdir}/glide-unwrapped --profile "\$profile" "\$@"
    EOF
    chmod +x $out/bin/glide

    mkdir -p $out/${runtimeSubdir}/distribution
    ln -s ${policiesJson} $out/${runtimeSubdir}/distribution/policies.json

    mkdir -p $out/share/applications
    cat > $out/share/applications/glide.desktop <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=Glide
    GenericName=Web Browser
    Exec=glide %U
    Icon=glide
    Terminal=false
    Categories=Network;WebBrowser;
    MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/pdf;image/png;image/jpeg;image/gif;image/webp;image/svg+xml;video/mp4;video/webm;audio/mpeg;audio/ogg;audio/wav;x-scheme-handler/about;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/mailto;
    Keywords=web;browser;internet;
    StartupNotify=true
    EOF

    for size in 16 32 48 64 128; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      cp $out/${runtimeSubdir}/browser/chrome/icons/default/default''${size}.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/glide.png
    done

    runHook postInstall
  '';

  meta = {
    description = "Extensible and keyboard-focused Firefox-based web browser";
    homepage = "https://glide-browser.app";
    license = pkgs.lib.licenses.mpl20;
    mainProgram = "glide";
    platforms = [ "x86_64-linux" ];
  };

  passthru = {
    firefoxpwaConnector = firefoxpwaConnectorOnly;
    firefoxpwaRuntimeIncluded = true;
    runtimePath = runtimeSubdir;
  };
}
