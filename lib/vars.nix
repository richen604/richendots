{ inputs, lib }:
let
  publicVars = {
    username = "richen";
  };

  privateVars = inputs.richendots-private.privateVars or { };
in
lib.recursiveUpdate publicVars privateVars
