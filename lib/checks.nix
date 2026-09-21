{
  inputs,
  lib,
  forEachSystem,
  pkgsFor,
}:
forEachSystem (
  system:
  let
    pkgs = pkgsFor system;
    privateSrc = lib.cleanSourceWith {
      src = inputs.richendots-private;
      filter = path: type: lib.cleanSourceFilter path type && baseNameOf path != ".direnv";
    };
    mkChecks =
      name: src:
      let
        nixFiles = ''
          mapfile -d "" files < <(find ${src} -name '*.nix' -type f -print0)
        '';
        textFiles = ''
          mapfile -d "" files < <(find ${src} -type f ! -name '*.patch' -print0 | sort -z)
        '';
      in
      {
        nixfmt = pkgs.runCommandLocal "${name}-nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          ${nixFiles}
          nixfmt --check "''${files[@]}"
          touch $out
        '';

        deadnix = pkgs.runCommandLocal "${name}-deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${src}
          touch $out
        '';

        statix = pkgs.runCommandLocal "${name}-statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
          statix check --config ${inputs.self}/statix.toml ${src}
          touch $out
        '';

        whitespace = pkgs.runCommandLocal "${name}-whitespace-check" { } ''
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
      };
  in
  mkChecks "richendots" inputs.self
  // lib.mapAttrs' (name: value: lib.nameValuePair "private-${name}" value) (
    mkChecks "richendots-private" privateSrc
  )
)
