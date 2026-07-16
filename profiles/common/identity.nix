{ hostvars, ... }:
{
  networking.hostName = hostvars.hostname;
  system.stateVersion = hostvars.stateVersion;
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";
}
