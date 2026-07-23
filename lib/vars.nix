{ inputs, lib }:
let
  publicVars = {
    username = "richen";
    theme = "grove";
  };

  privateVars = inputs.richendots-private.privateVars or { };
in
lib.recursiveUpdate publicVars privateVars
