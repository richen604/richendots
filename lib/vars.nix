{ inputs, lib }:
let
  publicVars = {
    username = "richen";
    theme = "grove";
    git.config = { };
    glide.searchEngines = [ ];
    keepassxc.localConfig.Browser = { };
    nix = {
      substituters = [ ];
      trustedPublicKeys = [ ];
    };
  };

  privateInput = inputs.richendots-private or { };
  privateVars = privateInput.privateVars or { };
in
lib.recursiveUpdate publicVars privateVars
