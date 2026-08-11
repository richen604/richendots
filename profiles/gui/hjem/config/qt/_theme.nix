{ theme }:
let
  colorGroup = background: alternate: ''
    BackgroundAlternate=${alternate}
    BackgroundNormal=${background}
    DecorationFocus=${theme.aliases.accentHover}
    DecorationHover=${theme.acc.p."8"}
    ForegroundActive=${theme.aliases.accentHover}
    ForegroundInactive=${theme.aliases.muted}
    ForegroundLink=${theme.syntax.type}
    ForegroundNegative=${theme.ui.error}
    ForegroundNeutral=${theme.ui.warning}
    ForegroundNormal=${theme.txt.p}
    ForegroundPositive=${theme.ui.success}
    ForegroundVisited=${theme.syntax.constant}
  '';
in
rec {
  kvantumConfigReplacements = {
    "bg-p" = theme.bg.p;
    "acc-p1" = theme.acc.p."1";
    "acc-p2" = theme.acc.p."2";
    "acc-p3" = theme.acc.p."3";
    "acc-p4" = theme.acc.p."4";
    "acc-p9" = theme.acc.p."9";
    "acc-s8" = theme.acc.s."8";
    "txt-p" = theme.txt.p;
  };

  kvantumSvgReplacements = kvantumConfigReplacements // {
    "bg-t" = theme.bg.t;
    "acc-p5" = theme.acc.p."5";
    "acc-p6" = theme.acc.p."6";
    "acc-p7" = theme.acc.p."7";
    "acc-p8" = theme.acc.p."8";
    "acc-s7" = theme.acc.s."7";
    "acc-s9" = theme.acc.s."9";
  };

  kdeglobals = ''
    [Colors:Button]
    ${colorGroup theme.bg.s theme.bg.t}
    [Colors:Complementary]
    ${colorGroup theme.bg.p theme.bg.t}
    [Colors:Selection]
    ${colorGroup theme.acc.p."2" theme.acc.p."3"}
    [Colors:Tooltip]
    ${colorGroup theme.bg.s theme.bg.t}
    [Colors:View]
    ${colorGroup theme.bg.p theme.bg.s}
    [Colors:Window]
    ${colorGroup theme.bg.p theme.bg.s}
    [General]
    ColorScheme=${theme.name}
    TerminalApplication=kitty
    fixed=GohuFont uni14 Nerd Font,14,-1,5,600,0,0,0,0,0,0,0,0,0,0,1,Regular
    font=GohuFont uni14 Nerd Font Propo,14,-1,5,600,0,0,0,0,0,0,0,0,0,0,1,Regular
    widgetStyle=kvantum

    [Icons]
    Theme=Papirus-Dark

    [Wallet]
    Enabled=false
  '';
}
