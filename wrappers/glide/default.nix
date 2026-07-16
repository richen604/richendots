{ pkgs, ... }:
let
  version = "0.1.63a";
  runtimeSubdir = "lib/glide-browser-${version}";
  pwaRuntimeSubdir = "lib/glide-pwa-runtime-${version}";
  policies = import ../firefox/_policies.nix;
  policiesJson = pkgs.writeText "glide-policies.json" (builtins.toJSON { inherit policies; });
  pwaPoliciesJson = pkgs.writeText "glide-pwa-policies.json" (
    builtins.toJSON {
      policies = {
        Preferences = {
          "media.eme.enabled" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "widget.dmabuf.force-enabled" = true;
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        DontCheckDefaultBrowser = true;
        DisableFirefoxStudies = true;
        DisableTelemetry = true;
        ExtensionSettings = {
          "addon@darkreader.org".installation_mode = "blocked";
          "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}".installation_mode = "blocked";
          "{74145f27-f039-47ce-a470-a662b129930a}".installation_mode = "blocked";
          "keepassxc-browser@keepassxc.org".installation_mode = "blocked";
          "sponsorBlocker@ajay.app".installation_mode = "blocked";
          "uBlock0@raymondhill.net".installation_mode = "blocked";
        };
      };
    }
  );

  # FirefoxPWA's native connector and patch assets, without its bundled Firefox runtime.
  firefoxpwaConnectorOnly = pkgs.firefoxpwa-unwrapped.overrideAttrs (old: {
    pname = "firefoxpwa-connector";
    postInstall = ''
      mkdir -p $out/share/firefoxpwa
      cp -r userchrome $out/share/firefoxpwa
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
        pwa_runtime=$out/${pwaRuntimeSubdir}

        mkdir -p "$glide_runtime" $out/bin $out/share/firefoxpwa
        cp -r . "$glide_runtime"
        mv "$glide_runtime/glide" "$glide_runtime/glide-unwrapped"
        ln -s "$glide_runtime/glide-unwrapped" "$glide_runtime/firefox"
        ln -s "$glide_runtime/glide-unwrapped" $out/bin/glide-unwrapped
        cp -r "$glide_runtime" "$pwa_runtime"
        rm "$pwa_runtime/firefox"
        ln -s "$pwa_runtime/glide-unwrapped" "$pwa_runtime/firefox"

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
    firefoxpwa_runtime="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/runtime"
    firefoxpwa_config="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/config.json"
    mkdir -p "\$(dirname "\$firefoxpwa_config")"
    if [ ! -f "\$firefoxpwa_config" ]; then
      cat > "\$firefoxpwa_config" <<'CONFIG_EOF'
    {"profiles":{"00000000000000000000000000":{"ulid":"00000000000000000000000000","name":"Default","description":"Default profile for all web apps","sites":[]}},"sites":{},"arguments":[],"variables":{},"config":{"always_patch":false,"runtime_enable_wayland":true,"runtime_use_xinput2":false,"runtime_use_portals":true,"use_linked_runtime":true}}
    CONFIG_EOF
    fi
    if [ -d "\$firefoxpwa_runtime" ] && [ ! -e "\$firefoxpwa_runtime/firefox" ] && [ ! -e "\$firefoxpwa_runtime/application.ini" ]; then
      rmdir "\$firefoxpwa_runtime" 2>/dev/null || true
    fi
    if [ -L "\$firefoxpwa_runtime" ] && [ "\$(readlink "\$firefoxpwa_runtime")" != "$out/${pwaRuntimeSubdir}" ]; then
      rm "\$firefoxpwa_runtime"
    fi
    if [ ! -e "\$firefoxpwa_runtime" ]; then
      mkdir -p "\$(dirname "\$firefoxpwa_runtime")"
      ln -s $out/${pwaRuntimeSubdir} "\$firefoxpwa_runtime"
    fi
    if [ -f "\$firefoxpwa_config" ]; then
      config_tmp="\$(mktemp)"
      if ${pkgs.jq}/bin/jq '.config.use_linked_runtime = true | .config.runtime_enable_wayland = true | .config.runtime_use_portals = true' "\$firefoxpwa_config" > "\$config_tmp"; then
        mv "\$config_tmp" "\$firefoxpwa_config"
      else
        rm -f "\$config_tmp"
      fi
    fi
    repair_desktop_entries() {
      for desktop_entry in "\''${XDG_DATA_HOME:-\$HOME/.local/share}"/applications/FFPWA-*.desktop; do
        [ -e "\$desktop_entry" ] || continue
        ${pkgs.gnused}/bin/sed -i \
          -e 's|^Exec=firefoxpwa |Exec=$out/bin/firefoxpwa |' \
          -e 's|^Exec=/nix/store/[^ ]*/bin/firefoxpwa |Exec=$out/bin/firefoxpwa |' \
          "\$desktop_entry"
      done
    }

    repair_desktop_entries
    if [ "\''${1:-}" = site ] && [ "\''${2:-}" = launch ] && [ -n "\''${3:-}" ]; then
      site_id="\$3"
      config="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/config.json"
      should_add_url=0
      if [ "\$#" -eq 3 ]; then
        should_add_url=1
      elif [ "\''${4:-}" = --protocol ] && { [ "\$#" -eq 4 ] || [ "\''${5:-}" = %u ]; }; then
        should_add_url=1
      fi

      if [ "\$should_add_url" -eq 1 ]; then
        fallback_url="\$(${pkgs.jq}/bin/jq -er --arg site_id "\$site_id" '.sites[\$site_id] | .config.start_url // .manifest.start_url // .config.document_url' "\$config" 2>/dev/null || true)"
        if [ -n "\$fallback_url" ]; then
          set -- site launch "\$site_id" --url "\$fallback_url"
        fi
      fi
    fi
    if [ "\''${1:-}" = site ] && [ "\''${2:-}" = launch ]; then
      exec ${firefoxpwaConnectorOnly}/bin/firefoxpwa "\$@"
    fi

    ${firefoxpwaConnectorOnly}/bin/firefoxpwa "\$@"
    status="\$?"
    repair_desktop_entries
    exit "\$status"
    EOF
        chmod +x $out/bin/firefoxpwa

        cat > $out/bin/firefoxpwa-connector <<EOF
    #!${pkgs.runtimeShell}
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_DISABLE_RDD_SANDBOX="\''${MOZ_DISABLE_RDD_SANDBOX:-1}"
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:${graphicsLibraryPath}:\''${LD_LIBRARY_PATH:-}"
    if [ -e /run/opengl-driver/lib/dri/nvidia_drv_video.so ]; then
      export LIBVA_DRIVER_NAME="\''${LIBVA_DRIVER_NAME:-nvidia}"
      export LIBVA_DRIVERS_PATH="/run/opengl-driver/lib/dri:\''${LIBVA_DRIVERS_PATH:-}"
      export NVD_BACKEND="\''${NVD_BACKEND:-direct}"
    fi
    firefoxpwa_runtime="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/runtime"
    firefoxpwa_config="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/config.json"
    mkdir -p "\$(dirname "\$firefoxpwa_config")"
    if [ ! -f "\$firefoxpwa_config" ]; then
      cat > "\$firefoxpwa_config" <<'CONFIG_EOF'
    {"profiles":{"00000000000000000000000000":{"ulid":"00000000000000000000000000","name":"Default","description":"Default profile for all web apps","sites":[]}},"sites":{},"arguments":[],"variables":{},"config":{"always_patch":false,"runtime_enable_wayland":true,"runtime_use_xinput2":false,"runtime_use_portals":true,"use_linked_runtime":true}}
    CONFIG_EOF
    fi
    if [ -d "\$firefoxpwa_runtime" ] && [ ! -e "\$firefoxpwa_runtime/firefox" ] && [ ! -e "\$firefoxpwa_runtime/application.ini" ]; then
      rmdir "\$firefoxpwa_runtime" 2>/dev/null || true
    fi
    if [ -L "\$firefoxpwa_runtime" ] && [ "\$(readlink "\$firefoxpwa_runtime")" != "$out/${pwaRuntimeSubdir}" ]; then
      rm "\$firefoxpwa_runtime"
    fi
    if [ ! -e "\$firefoxpwa_runtime" ]; then
      mkdir -p "\$(dirname "\$firefoxpwa_runtime")"
      ln -s $out/${pwaRuntimeSubdir} "\$firefoxpwa_runtime"
    fi
    if [ -f "\$firefoxpwa_config" ]; then
      config_tmp="\$(mktemp)"
      if ${pkgs.jq}/bin/jq '.config.use_linked_runtime = true | .config.runtime_enable_wayland = true | .config.runtime_use_portals = true' "\$firefoxpwa_config" > "\$config_tmp"; then
        mv "\$config_tmp" "\$firefoxpwa_config"
      else
        rm -f "\$config_tmp"
      fi
    fi
    repair_desktop_entries() {
      for desktop_entry in "\''${XDG_DATA_HOME:-\$HOME/.local/share}"/applications/FFPWA-*.desktop; do
        [ -e "\$desktop_entry" ] || continue
        ${pkgs.gnused}/bin/sed -i \
          -e 's|^Exec=firefoxpwa |Exec=$out/bin/firefoxpwa |' \
          -e 's|^Exec=/nix/store/[^ ]*/bin/firefoxpwa |Exec=$out/bin/firefoxpwa |' \
          "\$desktop_entry"
      done
    }

    repair_desktop_entries
    ${firefoxpwaConnectorOnly}/bin/firefoxpwa-connector "\$@"
    status="\$?"
    repair_desktop_entries
    exit "\$status"
    EOF
        chmod +x $out/bin/firefoxpwa-connector

        cat > $out/share/firefoxpwa/firefoxpwa.json <<EOF
    {"allowed_extensions":["firefoxpwa@filips.si"],"description":"The native part of the PWAsForFirefox project","name":"firefoxpwa","path":"$out/bin/firefoxpwa-connector","type":"stdio"}
    EOF

        # Patch a minimal FirefoxPWA runtime at build time. This keeps the runtime
        # immutable and avoids FirefoxPWA's normal downloaded Firefox copy while
        # keeping normal Glide browser policies out of PWA profiles.
        mkdir -p $out/share/firefoxpwa
        mkdir -p "$pwa_runtime/distribution"
        ln -s ${pwaPoliciesJson} "$pwa_runtime/distribution/policies.json"
        ln -s "$pwa_runtime" $out/share/firefoxpwa/runtime
        FFPWA_SYSDATA=${firefoxpwaConnectorOnly}/share/firefoxpwa \
          FFPWA_USERDATA=$out/share/firefoxpwa \
          ${firefoxpwaConnectorOnly}/bin/.firefoxpwa-wrapped runtime patch

        test -x $out/bin/firefoxpwa
        test -x $out/bin/firefoxpwa-connector
        test -e "$glide_runtime/firefox"
        test -e "$glide_runtime/application.ini"
        test -e "$pwa_runtime/firefox"
        test -e "$pwa_runtime/application.ini"
        test -e "$pwa_runtime/_autoconfig.cfg"
        test -e "$pwa_runtime/defaults/pref/autoconfig.js"

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
    firefoxpwa_config="\''${XDG_DATA_HOME:-\$HOME/.local/share}/firefoxpwa/config.json"
    mkdir -p "\$(dirname "\$firefoxpwa_config")"
    if [ ! -f "\$firefoxpwa_config" ]; then
      cat > "\$firefoxpwa_config" <<'CONFIG_EOF'
    {"profiles":{"00000000000000000000000000":{"ulid":"00000000000000000000000000","name":"Default","description":"Default profile for all web apps","sites":[]}},"sites":{},"arguments":[],"variables":{},"config":{"always_patch":false,"runtime_enable_wayland":true,"runtime_use_xinput2":false,"runtime_use_portals":true,"use_linked_runtime":true}}
    CONFIG_EOF
    fi
    if [ -d "\$firefoxpwa_runtime" ] && [ ! -e "\$firefoxpwa_runtime/firefox" ] && [ ! -e "\$firefoxpwa_runtime/application.ini" ]; then
      rmdir "\$firefoxpwa_runtime" 2>/dev/null || true
    fi
    if [ -L "\$firefoxpwa_runtime" ] && [ "\$(readlink "\$firefoxpwa_runtime")" != "$out/${pwaRuntimeSubdir}" ]; then
      rm "\$firefoxpwa_runtime"
    fi
    if [ ! -e "\$firefoxpwa_runtime" ]; then
      mkdir -p "\$(dirname "\$firefoxpwa_runtime")"
      ln -s $out/${pwaRuntimeSubdir} "\$firefoxpwa_runtime"
    fi
    if [ -f "\$firefoxpwa_config" ]; then
      config_tmp="\$(mktemp)"
      if ${pkgs.jq}/bin/jq '.config.use_linked_runtime = true | .config.runtime_enable_wayland = true | .config.runtime_use_portals = true' "\$firefoxpwa_config" > "\$config_tmp"; then
        mv "\$config_tmp" "\$firefoxpwa_config"
      else
        rm -f "\$config_tmp"
      fi
    fi
    mkdir -p "\$HOME/.glide-browser/native-messaging-hosts"
    ln -sf ${keepassxcNativeMessagingManifest} "\$HOME/.glide-browser/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
    ln -sf $out/share/firefoxpwa/firefoxpwa.json "\$HOME/.glide-browser/native-messaging-hosts/firefoxpwa.json"
    exec $out/${runtimeSubdir}/glide-unwrapped --profile "\$profile" "\$@"
    EOF
        chmod +x $out/bin/glide

        mkdir -p $out/${runtimeSubdir}/distribution
        ln -s ${policiesJson} $out/${runtimeSubdir}/distribution/policies.json

        mkdir -p $out/share/applications
        cat > $out/share/applications/glide.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Glide
    GenericName=Web Browser
    Exec=$out/bin/glide %U
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
