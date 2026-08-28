{
  lib,
  stdenvNoCC,
  nodejs,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  inputs,
  ...
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "equicord-asar";
  version = "unstable-${lib.substring 0 8 (inputs.equicord-src.rev or "unknown")}";

  src = inputs.equicord-src;

  EQUICORD_HASH = inputs.equicord-src.rev or "unknown";
  EQUICORD_REMOTE = "Equicord/Equicord";
  SOURCE_DATE_EPOCH = toString (inputs.equicord-src.lastModified or 1);

  # Backport Vencord bc68013: Discord moved message content into the parsed
  # message object, breaking plugins such as FakeNitro that modify text.
  postPatch = ''
    cp ${./message-events.ts} src/api/MessageEvents.ts
    cp ${./message-events-plugin.ts} src/plugins/_api/messageEvents.ts
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-VW4VKmM/12wl0sMFB9hG9K+sXjYVxlafu14IplGL/sw=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm build --standalone
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/equibop"
    cp -r dist/equibop/. "$out/equibop/"
    install -Dm0644 dist/equibop.asar "$out/equibop/equibop.asar"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    test -s "$out/equibop/equibop.asar"
    test -s "$out/equibop/main.js"
    test -s "$out/equibop/renderer.js"
    test -s "$out/equibop/preload.js"
  '';

  meta = {
    description = "Pinned Equicord ASAR with the upstream FakeNitro send fix";
    homepage = "https://github.com/Equicord/Equicord";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
  };
})
