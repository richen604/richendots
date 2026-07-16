{ lib }:
rec {
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
      lib.mapAttrsToList (name: flag: flagToArgs { inherit flagSeparator name flag; }) flags
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
}
