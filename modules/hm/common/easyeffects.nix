{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.common.easyeffects;
  # Community presets
  perfectEq = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Perfect%20EQ.json";
    name = "perfect-eq.json";
    sha256 = "sha256:0cppf5kcpp2spz7y38n0xwj83i4jkgvcbp06p1l005p2vs7xs59f";
  };

  # Professional NPR-style microphone preset with noise reduction
  microphonePreset = pkgs.writeText "microphone-noise-cancellation.json" (
    builtins.toJSON {
      "input" = {
        # NOTE: To test different noise reduction levels, you can:
        # 1. Adjust settings in EasyEffects GUI
        # 2. Export the preset and copy values here
        # 3. Or create multiple presets with different aggressiveness levels
        "blocklist" = [ ];
        "compressor#0" = {
          "attack" = 5.0;
          "boost-amount" = 6.0;
          "boost-threshold" = -72.0;
          "bypass" = false;
          "dry" = -100.0;
          "hpf-frequency" = 10.0;
          "hpf-mode" = "off";
          "input-gain" = 0.0;
          "knee" = -6.0;
          "lpf-frequency" = 20000.0;
          "lpf-mode" = "off";
          "makeup" = 0.0;
          "mode" = "Downward";
          "output-gain" = 0.0;
          "ratio" = 4.0;
          "release" = 75.0;
          "release-threshold" = -40.0;
          "sidechain" = {
            "lookahead" = 0.0;
            "mode" = "RMS";
            "preamp" = 0.0;
            "reactivity" = 10.0;
            "source" = "Middle";
            "stereo-split-source" = "Left/Right";
            "type" = "Feed-forward";
          };
          "stereo-split" = false;
          "threshold" = -20.0;
          "wet" = 0.0;
        };
        "deesser#0" = {
          "bypass" = false;
          "detection" = "RMS";
          "f1-freq" = 3000.0;
          "f1-level" = -6.0;
          "f2-freq" = 5000.0;
          "f2-level" = -6.0;
          "f2-q" = 1.5000000000000004;
          "input-gain" = 0.0;
          "laxity" = 15;
          "makeup" = 0.0;
          "mode" = "Wide";
          "output-gain" = 0.0;
          "ratio" = 5.0;
          "sc-listen" = false;
          "threshold" = -20.0;
        };
        "equalizer#0" = {
          "balance" = 0.0;
          "bypass" = false;
          "input-gain" = 0.0;
          "left" = {
            "band0" = {
              "frequency" = 50.0;
              "gain" = -6.0; # Reduce low frequencies (explosions, bass)
              "mode" = "RLC (BT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x1";
              "solo" = false;
              "type" = "Hi-pass";
              "width" = 4.0;
            };
            "band1" = {
              "frequency" = 90.0;
              "gain" = -3.0; # Reduce low-mid frequencies
              "mode" = "RLC (MT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x1";
              "solo" = false;
              "type" = "Lo-shelf";
              "width" = 4.0;
            };
            "band2" = {
              "frequency" = 425.0;
              "gain" = -4.0; # More reduction in mid frequencies where gaming audio is prominent
              "mode" = "BWC (MT)";
              "mute" = false;
              "q" = 0.9999999999999998;
              "slope" = "x2";
              "solo" = false;
              "type" = "Bell";
              "width" = 4.0;
            };
            "band3" = {
              "frequency" = 3500.0;
              "gain" = 3.0;
              "mode" = "BWC (BT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x2";
              "solo" = false;
              "type" = "Bell";
              "width" = 4.0;
            };
            "band4" = {
              "frequency" = 9000.0;
              "gain" = 2.0;
              "mode" = "LRX (MT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x1";
              "solo" = false;
              "type" = "Hi-shelf";
              "width" = 4.0;
            };
          };
          "mode" = "IIR";
          "num-bands" = 5;
          "output-gain" = 0.0;
          "pitch-left" = 0.0;
          "pitch-right" = 0.0;
          "right" = {
            "band0" = {
              "frequency" = 50.0;
              "gain" = -6.0; # Reduce low frequencies (explosions, bass)
              "mode" = "RLC (BT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x1";
              "solo" = false;
              "type" = "Hi-pass";
              "width" = 4.0;
            };
            "band1" = {
              "frequency" = 90.0;
              "gain" = -3.0; # Reduce low-mid frequencies
              "mode" = "RLC (MT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x1";
              "solo" = false;
              "type" = "Lo-shelf";
              "width" = 4.0;
            };
            "band2" = {
              "frequency" = 425.0;
              "gain" = -4.0; # More reduction in mid frequencies where gaming audio is prominent
              "mode" = "BWC (MT)";
              "mute" = false;
              "q" = 0.9999999999999998;
              "slope" = "x2";
              "solo" = false;
              "type" = "Bell";
              "width" = 4.0;
            };
            "band3" = {
              "frequency" = 3500.0;
              "gain" = 3.0;
              "mode" = "BWC (BT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x2";
              "solo" = false;
              "type" = "Bell";
              "width" = 4.0;
            };
            "band4" = {
              "frequency" = 9000.0;
              "gain" = 2.0;
              "mode" = "LRX (MT)";
              "mute" = false;
              "q" = 0.7;
              "slope" = "x1";
              "solo" = false;
              "type" = "Hi-shelf";
              "width" = 4.0;
            };
          };
          "split-channels" = false;
        };
        "gate#0" = {
          "attack" = 1.0;
          "bypass" = false;
          "curve-threshold" = -65.0; # Much lower threshold to catch gaming audio
          "curve-zone" = -2.0;
          "dry" = -100.0;
          "hpf-frequency" = 80.0; # High-pass filter to reduce gaming bass/explosions
          "hpf-mode" = "on";
          "hysteresis" = true;
          "hysteresis-threshold" = -8.0; # Wider hysteresis for more aggressive gating
          "hysteresis-zone" = -3.0;
          "input-gain" = 0.0;
          "lpf-frequency" = 20000.0;
          "lpf-mode" = "off";
          "makeup" = 2.0; # Slightly higher makeup gain
          "output-gain" = 0.0;
          "reduction" = -30.0; # Much more reduction when gate is closed
          "release" = 300.0; # Longer release to avoid cutting off speech
          "sidechain" = {
            "input" = "Internal";
            "lookahead" = 0.0;
            "mode" = "RMS";
            "preamp" = 0.0;
            "reactivity" = 10.0;
            "source" = "Middle";
            "stereo-split-source" = "Left/Right";
          };

          "stereo-split" = false;
          "wet" = -1.0;
        };
        "limiter#0" = {
          "alr" = false;
          "alr-attack" = 5.0;
          "alr-knee" = 0.0;
          "alr-release" = 50.0;
          "attack" = 1.0;
          "bypass" = false;
          "dithering" = "16bit";
          "external-sidechain" = false;
          "gain-boost" = true;
          "input-gain" = 0.0;
          "lookahead" = 5.0;
          "mode" = "Herm Wide";
          "output-gain" = 0.0;
          "oversampling" = "Half x2(2L)";
          "release" = 5.0;
          "sidechain-preamp" = 0.0;
          "stereo-link" = 100.0;
          "threshold" = -1.0;
        };
        "plugins_order" = [
          "rnnoise#0"
          "gate#0"
          "deesser#0"
          "compressor#0"
          "equalizer#0"
          "speex#0"
          "limiter#0"
        ];
        "rnnoise#0" = {
          "bypass" = false;
          "enable-vad" = true;
          "input-gain" = 0.0;
          "model-path" = "";
          "output-gain" = -25;
          "release" = 20.0;
          "vad-thres" = 50; # Voice Activity Detection: much more aggressive for nearby gaming noise
          "wet" = -1.0;
        };
        "speex#0" = {
          "bypass" = false;
          "enable-agc" = false;
          "enable-denoise" = true; # Enable additional denoising
          "enable-dereverb" = true; # Enable dereverb to reduce room reflections
          "input-gain" = 0.0;
          "noise-suppression" = -80; # Maximum noise suppression for gaming audio
          "output-gain" = 0.0;
          "vad" = {
            "enable" = true;
            "probability-continue" = 85; # Lower to be more selective about continuing speech
            "probability-start" = 98; # Higher to require clearer speech to start
          };
        };
      };
    }
  );
in
{
  options.modules.common.easyeffects = {
    enable = lib.mkEnableOption "EasyEffects audio effects";
  };

  config = lib.mkIf cfg.enable {
    # Install EasyEffects with noise reduction support
    home.packages = with pkgs; [
      easyeffects
      calf # Additional audio plugins
      lsp-plugins # More audio plugins
      rnnoise # RNNoise library for noise cancellation
      distrho-ports # Additional audio effects (corrected name)
      x42-plugins # Professional audio plugins with advanced filters
      zam-plugins # More audio processing plugins
      # Add noise profiling tools
      sox # For audio analysis and processing
      audacity # For noise profiling if needed
    ];

    # Enable EasyEffects service
    services.easyeffects = {
      enable = true;
      preset = "Perfect EQ"; # Default to Perfect EQ preset for output
    };

    # Install community presets and microphone noise cancellation preset
    xdg.configFile = {
      "easyeffects/output/Perfect EQ.json".source = perfectEq;
      "easyeffects/input/Microphone Noise Cancellation.json".source = microphonePreset;
    };
  };
}
