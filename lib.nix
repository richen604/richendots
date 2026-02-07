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
    import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
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
      pkgs =
        if hostvars.hostname == "fern" then
          import inputs.hydenix.inputs.nixpkgs {
            inherit (hostvars) system;
            config.allowUnfree = true;
            overlays = [ inputs.hydenix.overlays.default ];
          }
        else
          pkgsFor hostvars.system;

      richenLib = mkLib pkgs;
    in
    lib.nixosSystem {
      inherit pkgs;
      system = hostvars.system;

      specialArgs = {
        inputs = inputs // inputs.richendots-private.inputs;
        hostname = hostvars.hostname;
        inherit richenLib hostvars;
      };

      modules = [
        ./hosts/${hostvars.hostname}
        ./profiles/common.nix
        ./profiles/${hostvars.profile}.nix
        (inputs.richendots-private.nixosModules.${hostvars.hostname} or { })
      ];
      # todo: implement after fern migration
      # ++ lib.optional (
      #   hostvars.profile == "desktop" || hostvars.profile == "laptop"
      # ) ./profiles/common-gui.nix;
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
