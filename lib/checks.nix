{
  inputs,
  lib,
  forEachSystem,
  pkgsFor,
}:
let
  src = inputs.self;
in
forEachSystem (
  system:
  let
    pkgs = pkgsFor system;

    nixFiles = ''
      mapfile -d "" files < <(find ${src} -name '*.nix' -type f -print0)
    '';

    textFiles = ''
      mapfile -d "" files < <(find ${src} -type f -print0 | sort -z)
    '';
  in
  {
    nixfmt = pkgs.runCommandLocal "richendots-nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
      ${nixFiles}
      nixfmt --check "''${files[@]}"
      touch $out
    '';

    deadnix =
      pkgs.runCommandLocal "richendots-deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; }
        ''
          deadnix --fail ${src}
          touch $out
        '';

    statix = pkgs.runCommandLocal "richendots-statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
      statix check --config ${src}/statix.toml ${src}
      touch $out
    '';

    whitespace = pkgs.runCommandLocal "richendots-whitespace-check" { } ''
      ${textFiles}

      ${lib.getExe pkgs.perl} -e '
        my $bad = 0;
        for my $file (@ARGV) {
          next if -B $file;
          open my $fh, "<", $file or die "$file: $!\n";
          my $line = 0;
          while (my $text = <$fh>) {
            $line++;
            if ($text =~ /[ \t]+\n?\z/) {
              print "$file:$line: trailing whitespace\n";
              $bad = 1;
            }
          }
        }
        exit $bad;
      ' "''${files[@]}"

      ${lib.getExe pkgs.perl} -e '
        my $bad = 0;
        for my $file (@ARGV) {
          next if -B $file;
          next unless -s $file;
          open my $fh, "<", $file or die "$file: $!\n";
          seek $fh, -1, 2 or die "$file: $!\n";
          read $fh, my $last, 1;
          if ($last ne "\n") {
            print "$file: missing final newline\n";
            $bad = 1;
          }
        }
        exit $bad;
      ' "''${files[@]}"

      touch $out
    '';
  }
)
