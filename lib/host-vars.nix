{ inputs }:
let
  privateInput = inputs.richendots-private or { };
  publicHostVars = {
    fern = {
      cursorSize = 24;
      hostname = "fern";
      system = "x86_64-linux";
      profiles = [
        "common"
        "gui"
        "desktop"
      ];
      stateVersion = "26.05";
    };

    oak = {
      cursorSize = 36;
      hostname = "oak";
      system = "x86_64-linux";
      profiles = [
        "common"
        "gui"
        "laptop"
      ];
      stateVersion = "26.05";
    };

    cedar = {
      hostname = "cedar";
      system = "x86_64-linux";
      profiles = [
        "common"
        "server"
      ];
      stateVersion = "25.05";
    };
  };
in
publicHostVars // (privateInput.hostVars or { })
