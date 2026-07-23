{
  pkgs,
  richenLib,
  ...
}:
let
  config = (pkgs.formats.json { }).generate "swaync-config" {
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    control-center-layer = "overlay";
    layer-shell = true;
    cssPriority = "user";
    control-center-margin-top = 10;
    control-center-margin-bottom = 10;
    control-center-margin-right = 10;
    control-center-margin-left = 0;
    notification-2fa-action = true;
    notification-inline-replies = false;
    notification-icon-size = 64;
    notification-body-image-height = 100;
    notification-body-image-width = 200;
    timeout = 10;
    timeout-low = 5;
    timeout-critical = 0;
    fit-to-screen = false;
    control-center-width = 500;
    control-center-height = 600;
    notification-window-width = 400;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 200;
    hide-on-clear = false;
    hide-on-action = true;
    script-fail-notify = false;
  };
  swayncTheme = import ./_theme.nix { theme = richenLib.theme; };
  defineGtkColors =
    colors:
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (name: value: "@define-color ${name} ${value};") colors
    );
  style = pkgs.writeText "style.css" ''
    ${defineGtkColors swayncTheme.colors}

    * {
      all: unset;
      font-family: FiraCode Nerd Font;
      transition: 0.3s;
      font-size: 1.2rem;
    }

    .floating-notifications.background .notification-row {
      padding: 1rem;
    }

    .floating-notifications.background .notification-row .notification-background {
      border-radius: 0.5rem;
      background-color: @bg-primary;
      color: @fg-primary;
      border: 1px solid @border-color;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification {
      padding: 0.5rem;
      border-radius: 0.5rem;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification.critical {
      border: 1px solid @critical-color;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      .notification-content
      .summary {
      margin: 0.5rem;
      color: @fg-primary;
      font-weight: bold;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      .notification-content
      .body {
      margin: 0.5rem;
      color: @fg-secondary;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > * {
      min-height: 3rem;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action {
      border-radius: 0.5rem;
      color: @fg-primary;
      background-color: @bg-secondary;
      border: 1px solid @border-color;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:hover {
      background-color: @hover-bg;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:active {
      background-color: @active-bg;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button {
      margin: 0.5rem;
      padding: 0.25rem;
      border-radius: 0.5rem;
      color: @bg-primary;
      background-color: @critical-color;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button:hover {
      color: @fg-primary;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button:active {
      background-color: @fg-secondary;
    }

    .control-center {
      border-radius: 0.5rem;
      margin: 1rem;
      background-color: @bg-primary;
      color: @fg-primary;
      padding: 1rem;
      border: 1px solid @border-color;
    }

    .control-center .widget-title {
      color: @accent-primary;
      font-weight: bold;
    }

    .control-center .widget-title button {
      border-radius: 0.5rem;
      color: @fg-primary;
      background-color: @bg-secondary;
      border: 1px solid @border-color;
      padding: 0.5rem;
    }

    .control-center .widget-title button:hover {
      background-color: @hover-bg;
    }

    .control-center .widget-title button:active {
      background-color: @active-bg;
    }

    .control-center .notification-row .notification-background {
      border-radius: 0.5rem;
      margin: 0.5rem 0;
      background-color: @bg-secondary;
      color: @fg-primary;
      border: 1px solid @border-color;
    }

    .control-center .notification-row .notification-background .notification {
      padding: 0.5rem;
      border-radius: 0.5rem;
    }

    .control-center
      .notification-row
      .notification-background
      .notification.critical {
      border: 1px solid @critical-color;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      .notification-content {
      color: @fg-primary;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      .notification-content
      .summary {
      margin: 0.5rem;
      color: @fg-primary;
      font-weight: bold;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      .notification-content
      .body {
      margin: 0.5rem;
      color: @fg-secondary;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > * {
      min-height: 3rem;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action {
      border-radius: 0.5rem;
      color: @fg-primary;
      background-color: @bg-secondary;
      border: 1px solid @border-color;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:hover {
      background-color: @hover-bg;
    }

    .control-center
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:active {
      background-color: @active-bg;
    }

    .control-center .notification-row .notification-background .close-button {
      margin: 0.5rem;
      padding: 0.25rem;
      border-radius: 0.5rem;
      color: @bg-primary;
      background-color: @critical-color;
    }

    .control-center .notification-row .notification-background .close-button:hover {
      color: @fg-primary;
    }

    .control-center
      .notification-row
      .notification-background
      .close-button:active {
      background-color: @fg-secondary;
    }

    progressbar,
    progress,
    trough {
      border-radius: 0.5rem;
    }

    .notification.critical progress {
      background-color: @critical-color;
    }

    .notification.low progress,
    .notification.normal progress {
      background-color: @accent-tertiary;
    }

    trough {
      background-color: @bg-secondary;
    }

    .control-center trough {
      background-color: @border-color;
    }

    .control-center-dnd {
      margin: 1rem 0;
      border-radius: 0.5rem;
    }

    .control-center-dnd slider {
      background: @hover-bg;
      border-radius: 0.5rem;
    }

    .widget-dnd {
      color: @fg-secondary;
    }

    .widget-dnd > switch {
      border-radius: 0.5rem;
      background: @hover-bg;
      border: 1px solid @border-color;
    }

    .widget-dnd > switch:checked slider {
      background: @accent-secondary;
    }

    .widget-dnd > switch slider {
      background: @border-color;
      border-radius: 0.5rem;
      margin: 0.25rem;
    }
  '';
in
richenLib.lib.wrapPackage {
  package = pkgs.swaynotificationcenter;
  filesToPatch = [ "share/systemd/user/swaync.service" ];
  flags = {
    "-c" = config;
    "-s" = style;
  };
  passthru = {
    config.path = config;
    style.path = style;
  };
}
