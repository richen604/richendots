{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  forEachSystem = f: lib.genAttrs systems f;

  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          waybar = (prev.waybar.override { cavaSupport = false; }).overrideAttrs (_old: {
            version = "0.16.0-unstable-2026-07-12";
            src = final.fetchFromGitHub {
              owner = "Alexays";
              repo = "Waybar";
              rev = "cf19c836d3dafc1646bb60a49269d981623b680a";
              hash = "sha256-h1ZmLmqBkm3MyShV6p83kBtpeLa9rnZUVz75kp+0Ccw=";
            };
            buildInputs = _old.buildInputs ++ [ final.modemmanager ];
            doInstallCheck = false;
          });
        })
      ];
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "olivetin-2025.11.25"
        ];
      };
    };

  nameFromPath =
    path:
    let
      base = lib.removeSuffix ".nix" (baseNameOf path);
    in
    if base == "default" then baseNameOf (dirOf path) else base;

  mkLib =
    pkgs:
    let
      self = {
        vars.username = "richen";

        lib = {
          flagToArgs =
            {
              flagSeparator ? null,
              name,
              flag,
            }:
            if flag == false then
              [ ]
            else if flag == true then
              [ name ]
            else if lib.isStringLike flag then
              if flagSeparator == null then
                [
                  name
                  (toString flag)
                ]
              else
                [ "${name}${flagSeparator}${toString flag}" ]
            else if lib.isList flag then
              lib.concatMap (
                v:
                if lib.isStringLike v then
                  if flagSeparator == null then
                    [
                      name
                      (toString v)
                    ]
                  else
                    [ "${name}${flagSeparator}${toString v}" ]
                else if builtins.isList v then
                  [ name ] ++ map toString v
                else
                  throw "flag ${name} has unsupported list element type ${lib.typeOf v}"
              ) flag
            else
              throw "flag ${name} has unsupported type ${lib.typeOf flag}";

          generateArgsFromFlags =
            flags: flagSeparator:
            lib.concatLists (
              lib.mapAttrsToList (name: flag: self.lib.flagToArgs { inherit flagSeparator name flag; }) flags
            );

          escapeShellArgWithEnv =
            arg:
            let
              escaped =
                lib.replaceStrings
                  [
                    ''\''
                    ''"''
                  ]
                  [
                    ''\\''
                    ''\"''
                  ]
                  (toString arg);
            in
            ''"${escaped}"'';

          wrapPackage =
            {
              package,
              exePath ? lib.getExe package,
              binName ? baseNameOf exePath,
              runtimeInputs ? [ ],
              env ? { },
              flags ? { },
              flagSeparator ? null,
              args ? self.lib.generateArgsFromFlags flags flagSeparator ++ [ "$@" ],
              preHook ? "",
              postHook ? "",
              passthru ? { },
              aliases ? [ ],
              filesToPatch ? [ "share/applications/*.desktop" ],
              filesToExclude ? [ ],
              patchHook ? "",
              wrapper ? (
                {
                  exePath,
                  flagsString,
                  envString,
                  preHook,
                  postHook,
                  ...
                }:
                ''
                  ${envString}
                  ${preHook}
                  ${lib.optionalString (postHook == "") "exec"} ${exePath}${flagsString}
                  ${postHook}
                ''
              ),
            }@funcArgs:
            let
              envString = lib.concatStringsSep "\n" (
                lib.mapAttrsToList (name: value: ''export ${name}="${toString value}"'') env
              );

              flagsString = lib.optionalString (args != [ ]) (
                " " + lib.concatStringsSep " " (map self.lib.escapeShellArgWithEnv args)
              );

              finalWrapper = wrapper {
                inherit
                  env
                  flags
                  args
                  envString
                  flagsString
                  exePath
                  preHook
                  postHook
                  ;
              };

              runtimePath = lib.optionalString (runtimeInputs != [ ]) ''
                export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
              '';

              wrapperScriptContent = "#!${pkgs.runtimeShell}\n" + runtimePath + finalWrapper;

              originalOutputs =
                if package ? outputs then
                  lib.listToAttrs (
                    map (output: {
                      name = output;
                      value = if package ? ${output} then package.${output} else null;
                    }) package.outputs
                  )
                else
                  { };
            in
            pkgs.stdenv.mkDerivation {
              name = package.pname or package.name;
              passthru = (package.passthru or { }) // passthru;
              outputs = if package ? outputs then package.outputs else [ "out" ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              meta = (package.meta or { }) // {
                mainProgram = binName;
              };
              buildCommand = ''
                mkdir -p $out
                ${pkgs.lndir}/bin/lndir -silent ${package} $out

                ${lib.optionalString (filesToExclude != [ ]) ''
                  ${lib.concatMapStringsSep "\n" (pattern: ''
                    for file in $out/${pattern}; do
                      if [[ -e "$file" ]]; then
                        rm -f "$file"
                      fi
                    done
                  '') filesToExclude}
                ''}

                mkdir -p $out/bin
                rm -f $out/bin/${binName}
                mkdir -p $out/libexec
                wrapperScript="$out/libexec/${binName}-wrapper"
                printf '%s' ${lib.escapeShellArg wrapperScriptContent} > "$wrapperScript"
                chmod +x "$wrapperScript"
                makeWrapper "$wrapperScript" $out/bin/${binName}

                ${lib.optionalString (filesToPatch != [ ]) ''
                  oldPath="${package}"
                  newPath="$out"
                  ${lib.concatMapStringsSep "\n" (pattern: ''
                    for file in $out/${pattern}; do
                      if [[ -L "$file" ]]; then
                        target=$(readlink -f "$file")
                        if grep -qF "$oldPath" "$target" 2>/dev/null; then
                          rm "$file"
                          substitute "$target" "$file" --replace-fail "$oldPath" "$newPath"
                          chmod --reference="$target" "$file"
                        fi
                      fi
                    done
                  '') filesToPatch}
                ''}

                ${patchHook}

                ${lib.optionalString (aliases != [ ]) ''
                  for alias in ${lib.concatStringsSep " " (map lib.escapeShellArg aliases)}; do
                    ln -sf ${lib.escapeShellArg binName} $out/bin/$alias
                  done
                ''}

                ${lib.concatMapStringsSep "\n" (
                  output:
                  lib.optionalString
                    (output != "out" && originalOutputs ? ${output} && originalOutputs.${output} != null)
                    ''
                      if [[ -n "''${${output}:-}" ]]; then
                        mkdir -p ${"$" + output}
                        ${pkgs.lndir}/bin/lndir -silent "${originalOutputs.${output}}" ${"$" + output}
                      fi
                    ''
                ) (if package ? outputs then package.outputs else [ "out" ])}
              '';
            };

          listFilesRecursiveCond =
            dir: condition:
            let
              go =
                folder:
                let
                  contents = builtins.readDir folder;
                  names = builtins.attrNames contents;
                in
                builtins.concatMap (
                  name:
                  let
                    type = contents.${name};
                    path = folder + "/${name}";
                  in
                  if type == "regular" && condition name then
                    [ path ]
                  else if type == "directory" then
                    go path
                  else
                    [ ]
                ) names;
            in
            go dir;
        };

        wrappers =
          let
            files = self.lib.listFilesRecursiveCond ./wrappers (
              filename:
              lib.hasSuffix ".nix" filename && filename != "module.nix" && lib.hasPrefix "_" filename == false
            );
          in
          lib.listToAttrs (
            map (
              path:
              lib.nameValuePair (nameFromPath path) (
                pkgs.callPackage path {
                  inherit inputs;
                  richenLib = self;
                }
              )
            ) files
          );
      };
    in
    self;

  mkHost =
    hostvars:
    let
      pkgs = pkgsFor hostvars.system;
      richenLib = mkLib pkgs;
      recursiveModules =
        dir:
        richenLib.lib.listFilesRecursiveCond dir (
          filename: lib.hasSuffix ".nix" filename && filename != "default.nix" && !lib.hasPrefix "_" filename
        );
    in
    lib.nixosSystem {
      inherit pkgs;
      system = hostvars.system;
      specialArgs = {
        inputs = inputs // inputs.richendots-private.inputs;
        hostname = hostvars.hostname;
        inherit richenLib hostvars;
      };

      modules =
        recursiveModules ./profiles/common
        ++ lib.optionals (hostvars.profile == "desktop" || hostvars.profile == "laptop") (
          recursiveModules ./profiles/gui
        )
        ++ recursiveModules ./profiles/${hostvars.profile}
        ++ recursiveModules ./hosts/${hostvars.hostname}
        ++ [ (inputs.richendots-private.nixosModules.${hostvars.hostname} or { }) ];
    };

  mkVm =
    hostvars:
    (import ./hosts/vm.nix {
      inherit inputs;
      nixosConfiguration = mkHost hostvars;
    }).config.system.build.vm;

in
{
  inherit
    pkgsFor
    forEachSystem
    mkLib
    mkHost
    mkVm
    ;
}
