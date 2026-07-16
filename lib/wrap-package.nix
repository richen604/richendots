{
  helpers,
  lib,
  pkgs,
}:
{
  package,
  exePath ? lib.getExe package,
  binName ? baseNameOf exePath,
  runtimeInputs ? [ ],
  env ? { },
  flags ? { },
  flagSeparator ? null,
  args ? helpers.generateArgsFromFlags flags flagSeparator ++ [ "$@" ],
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
    " " + lib.concatStringsSep " " (map helpers.escapeShellArgWithEnv args)
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
}
