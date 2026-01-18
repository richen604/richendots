{
  inputs,
  pkgs,
  ...
}:

(inputs.wrappers.wrapperModules.udiskie.apply {
  pkgs = pkgs;
  settings = {
    program_options = {
      tray = true;
      automount = true;
      notify = true;
    };
  };
}).wrapper
