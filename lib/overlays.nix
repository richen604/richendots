{ inputs }:
[
  (final: prev: {
    waybar = (prev.waybar.override { cavaSupport = false; }).overrideAttrs (_old: {
      version = "0.16.0-unstable-2026-07-12";
      src = final.fetchFromGitHub {
        owner = "Alexays";
        repo = "Waybar";
        rev = "cf19c836d3dafc1646bb60a49269d981623b680a";
        hash = "sha256-h1ZmLmqBkm3MyShV6p83kBtpeLa9rnZUVz75kp+0Ccw=";
      };
      buildInputs = _old.buildInputs ++ [ final.modemmanager ];
      doInstallCheck = false;
    });
  })
]
