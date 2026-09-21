{ inputs }:
let
  publicHostVars = {
    fern = {
      hostname = "fern";
      system = "x86_64-linux";
      profile = "desktop";
      stateVersion = "26.05";
    };

    oak = {
      hostname = "oak";
      system = "x86_64-linux";
      profile = "laptop";
      stateVersion = "26.05";
    };

    cedar = {
      hostname = "cedar";
      system = "x86_64-linux";
      profile = "server";
      stateVersion = "25.05";
    };
  };
in
publicHostVars // (inputs.richendots-private.hostVars or { })
