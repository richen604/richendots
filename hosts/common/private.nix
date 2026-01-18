{ pkgs, richenLib, ... }:

{
  # todo: this should be a shell
  # Inits some required packages for richendots-private
  environment.systemPackages = with pkgs; [
    # YubiKey management tools
    yubikey-manager # CLI tool for configuring YubiKeys
    yubikey-personalization # Required for challenge-response
    yubioath-flutter # Authenticator app for TOTP/HOTP
    yubikey-touch-detector # Detects YubiKey touch events
    # Age encryption with YubiKey support
    age # Core age encryption
    age-plugin-yubikey # YubiKey plugin for age
    richenLib.wrappers.keepassxc
    pam_u2f
  ];
}
