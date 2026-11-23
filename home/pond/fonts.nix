# The fonts Pond names, as one folder for ~/.local/share/fonts. Its title font: the shell, lock
# screen and launcher ask for "Pond Gramercy", Butterfly's own cut of ABC Gramercy, which isn't
# public; Dinamo's trial of ABC Gramercy stands in for it (fontconfig rule in default.nix).
# Licensed, so not in git: the zip is gitignored and goes into the store by hand.
{
  runCommand,
  requireFile,
  unzip,
  ibm-plex,
  jetbrains-mono,
  pond, # Onest, Advent Pro
}:
let
  trialZip = requireFile {
    name = "dinamo-gramercy-trial.zip";
    hash = "sha256-XVy/g61Z5ZaLhfYbjR81wsEmFgcpW1C8ElW10bnfWCs=";
    message = ''
      dinamo-gramercy-trial.zip (Dinamo's "DINAMO Trial Fonts.zip", Gramercy) is licensed and
      gitignored. Copy it to home/pond/fonts/, add it to the store, then build again:
        nix store add-file ~/nix-config/home/pond/fonts/dinamo-gramercy-trial.zip
    '';
  };
in
runCommand "pond-fonts" { nativeBuildInputs = [ unzip ]; } ''
  mkdir -p $out/gramercy
  ln -s ${pond}/share/fonts $out/pond
  ln -s ${ibm-plex.override { families = [ "mono" ]; }}/share/fonts $out/ibm-plex-mono
  ln -s ${jetbrains-mono}/share/fonts $out/jetbrains-mono
  # The text cut only: it has the Book and Regular styles Pond asks for
  unzip -j ${trialZip} 'Gramercy/ABC Gramercy/*.otf' -d $out/gramercy
  # Keep the zip alive with the font, so garbage collection can't break a later rebuild
  ln -s ${trialZip} $out/gramercy/.source.zip
''
