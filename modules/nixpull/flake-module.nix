{ inputs, self }:

let
  lib = inputs.nixpkgs.lib;
  hosts = self.nixosConfigurations;

  hostSystem = host: hosts.${host}.pkgs.system;
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
in
{
  nixpullProfiles = lib.mapAttrs (host: _configuration: activatable host) hosts;
  inherit deploy;
  checks = lib.mapAttrs (_system: deployLib: deployLib.deployChecks deploy) inputs.deploy-rs.lib;
}
