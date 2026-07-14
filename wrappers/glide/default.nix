{ pkgs, ... }:
let
  version = "0.1.63a";
  policies = import ../firefox/policies.nix;
  policiesJson = pkgs.writeText "glide-policies.json" (builtins.toJSON { inherit policies; });
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
  chromeCss = pkgs.replaceVars ../firefox/userChrome.css {
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

    mkdir -p $out/lib/glide-browser-${version} $out/bin
    cp -r . $out/lib/glide-browser-${version}
    mv $out/lib/glide-browser-${version}/glide $out/lib/glide-browser-${version}/glide-unwrapped
    ln -s $out/lib/glide-browser-${version}/glide-unwrapped $out/bin/glide-unwrapped

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
    ln -sf ${chromeCss} "\$profile/chrome/userChrome.css"
    exec $out/lib/glide-browser-${version}/glide-unwrapped --profile "\$profile" "\$@"
    EOF
    chmod +x $out/bin/glide

    mkdir -p $out/lib/glide-browser-${version}/distribution
    ln -s ${policiesJson} $out/lib/glide-browser-${version}/distribution/policies.json

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
    MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/pdf;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/about;
    StartupNotify=true
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Extensible and keyboard-focused Firefox-based web browser";
    homepage = "https://glide-browser.app";
    license = pkgs.lib.licenses.mpl20;
    mainProgram = "glide";
    platforms = [ "x86_64-linux" ];
  };
}
