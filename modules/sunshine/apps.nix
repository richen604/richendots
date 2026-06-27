{
  sunshinePackage,
  sunshineHeadlessSetResolution,
  sunshineHeadlessResetResolution,
  sunshineSteamGamepadUi,
  sunshineCloseSteamGamepadUi,
}:
let
  headlessStreamPrep = [
    {
      do = "${sunshineHeadlessSetResolution}/bin/sunshine-headless-set-resolution";
      undo = "${sunshineHeadlessResetResolution}/bin/sunshine-headless-reset-resolution";
    }
  ];
in
[
  {
    name = "Desktop";
    image-path = "${sunshinePackage}/assets/desktop.png";
    prep-cmd = headlessStreamPrep;
    exclude-global-prep-cmd = "false";
    auto-detach = "true";
  }
  {
    name = "Steam Gamepad UI";
    image-path = "${sunshinePackage}/assets/steam.png";
    prep-cmd = headlessStreamPrep ++ [
      {
        do = "";
        undo = "${sunshineCloseSteamGamepadUi}/bin/sunshine-close-steam-gamepad-ui";
      }
    ];
    cmd = "${sunshineSteamGamepadUi}/bin/sunshine-steam-gamepad-ui";
    exclude-global-prep-cmd = "false";
  }
]
