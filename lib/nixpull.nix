{
  inputs,
  lib,
  nixosConfigurations,
}:
let
  hosts = nixosConfigurations;
  hostSystem = host: hosts.${host}.pkgs.stdenv.hostPlatform.system;
  systems = lib.unique (map hostSystem (lib.attrNames hosts));
  deployLibs = lib.genAttrs systems (system: inputs.deploy-rs.lib.${system});

  activatable = host: inputs.deploy-rs.lib.${hostSystem host}.activate.nixos hosts.${host};
  deploy = {
    nodes = lib.mapAttrs (host: _configuration: {
      hostname = host;
      profiles.system = {
        user = "root";
        path = activatable host;
      };
    }) hosts;
  };

  deployChecks = lib.mapAttrs (_system: deployLib: deployLib.deployChecks deploy) deployLibs;
in
{
  nixpullProfiles = lib.mapAttrs (host: _configuration: activatable host) hosts;
  inherit deploy;
  inherit deployChecks;
}
