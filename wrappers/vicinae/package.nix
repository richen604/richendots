{
  abseil-cpp,
  cmake,
  cmark-gfm,
  fetchNpmDeps,
  fetchFromGitHub,
  kdePackages,
  lib,
  libqalculate,
  minizip,
  ninja,
  nodejs,
  npmHooks,
  pkg-config,
  protobuf,
  qt6,
  gcc15Stdenv,
  wayland,
  libxml2,
  glaze,
  ...
}:
gcc15Stdenv.mkDerivation (finalAttrs: {
  pname = "vicinae";
  version = "0.19.2"; # Hardcoded from manifest.yaml

  src = fetchFromGitHub {
    owner = "vicinaehq";
    repo = "vicinae";
    rev = "92cb677fca1513266bc63235e2d01a28f165ee41"; # From manifest.yaml
    hash = "sha256-YXFSCJ4q1XIom4/CzCy4ASt7RDjxSkIWH6MqrCg+PNY="; # From nix-prefetch-github
  };

  apiDeps = fetchNpmDeps {
    src = "${finalAttrs.src}/typescript/api";
    hash = "sha256-UsTpMR23UQBRseRo33nbT6z/UCjZByryWfn2AQSgm6U=";
  };

  extensionManagerDeps = fetchNpmDeps {
    src = "${finalAttrs.src}/typescript/extension-manager";
    hash = "sha256-wl8FDFB6Vl1zD0/s2EbU6l1KX4rwUW6dOZof4ebMMO8=";
  };

  cmakeFlags = lib.mapAttrsToList lib.cmakeFeature {
    "VICINAE_GIT_TAG" = "v${finalAttrs.version}";
    "VICINAE_GIT_COMMIT_HASH" = "92cb677fc"; # Hardcoded short_rev from manifest.yaml
    "VICINAE_PROVENANCE" = "nix";
    "INSTALL_NODE_MODULES" = "OFF";
    "USE_SYSTEM_GLAZE" = "ON";
    "CMAKE_INSTALL_PREFIX" = placeholder "out";
    "CMAKE_INSTALL_DATAROOTDIR" = "share";
    "CMAKE_INSTALL_BINDIR" = "bin";
    "CMAKE_INSTALL_LIBDIR" = "lib";
    "INSTALL_BROWSER_NATIVE_HOST" = "OFF";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    ninja
    nodejs
    pkg-config
    protobuf
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    abseil-cpp
    cmark-gfm
    kdePackages.layer-shell-qt
    kdePackages.qtkeychain
    libqalculate
    minizip
    nodejs
    protobuf
    qt6.qtbase
    qt6.qtsvg
    qt6.qtwayland
    wayland
    libxml2
    glaze
  ];

  postPatch = ''
    local postPatchHooks=()
    source ${npmHooks.npmConfigHook}/nix-support/setup-hook
    npmRoot=typescript/api npmDeps=${finalAttrs.apiDeps} npmConfigHook
    npmRoot=typescript/extension-manager npmDeps=${finalAttrs.extensionManagerDeps} npmConfigHook
  '';

  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        nodejs
        (placeholder "out")
      ]
    }"
  ];

  meta = {
    description = "A focused launcher for your desktop — native, fast, extensible";
    homepage = "https://github.com/vicinaehq/vicinae";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "vicinae";
  };
})
