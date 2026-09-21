{
  config,
  inputs,
  ...
}:
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  services.flatpak = {
    packages =
      map
        (appId: {
          inherit appId;
          origin = "flathub";
        })
        [
          "com.obsproject.Studio"
          "com.obsproject.Studio.Plugin.BackgroundRemoval"
          "com.obsproject.Studio.Plugin.CompositeBlur"
          "com.obsproject.Studio.Plugin.MoveTransition"
          "com.obsproject.Studio.Plugin.OBSVkCapture"
          "com.obsproject.Studio.Plugin.PipeWireAudioCapture"
          "org.freedesktop.Platform.VulkanLayer.OBSVkCapture//25.08"
        ];
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
    uninstallUnmanaged = false;
  };

  boot = {
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';
  };
}
