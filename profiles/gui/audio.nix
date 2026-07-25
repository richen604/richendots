{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.playerctl
  ];

  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.pipewire.wireplumber.extraConfig."10-bluez-roles" = {
    "monitor.bluez.properties"."bluez5.roles" = [
      "a2dp_sink"
      "a2dp_source"
    ];
  };
}
