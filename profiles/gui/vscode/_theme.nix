{ theme }:
let
  inherit (theme)
    aliases
    diff
    markup
    syntax
    ;
in
{
  label = "${theme.name} Dark";
  extensionName = "richendots-theme";
  replacements = {
    background = theme.bg.p;
    backgroundSecondary = theme.bg.s;
    backgroundTertiary = theme.bg.t;
    foreground = theme.txt.p;
    foregroundSecondary = theme.txt.s;
    foregroundMuted = aliases.muted;
    accent = aliases.accent;
    accentHover = aliases.accentHover;
    border = theme.acc.p."2";
    borderStrong = theme.acc.p."3";
    selection = aliases.selection;
    success = theme.ui.success;
    warning = theme.ui.warning;
    error = theme.ui.error;
    info = theme.ui.info;

    syntaxForeground = syntax.foreground;
    syntaxComment = syntax.comment;
    syntaxKeyword = syntax.keyword;
    syntaxString = syntax.string;
    syntaxNumber = syntax.number;
    syntaxFunction = syntax.function;
    syntaxVariable = syntax.variable;
    syntaxType = syntax.type;
    syntaxOperator = syntax.operator;
    syntaxConstant = syntax.constant;
    syntaxException = syntax.exception;

    markupHeading = markup.heading;
    markupLink = markup.link;
    markupEmphasis = markup.emphasis;
    markupStrong = markup.strong;
    markupCode = markup.code;
    markupQuote = markup.quote;
    diffAdded = diff.added;
    diffAddedBackground = diff.addedBackground;
    diffRemoved = diff.removed;
    diffRemovedBackground = diff.removedBackground;
    diffModified = diff.modified;
    diffModifiedBackground = diff.modifiedBackground;
    lineNumber = diff.lineNumber;
    lineNumberActive = diff.lineNumberActive;
  };
}
