{ theme }:
{
  replacements = {
    "background-primary" = theme.bg.p;
    "background-secondary" = theme.bg.s;
    "background-tertiary" = theme.bg.t;
    "text-primary" = theme.txt.p;
    "text-secondary" = theme.txt.s;
    "text-tertiary" = theme.txt.t;

    "accent-primary-1" = theme.acc.p."1";
    "accent-primary-2" = theme.acc.p."2";
    "accent-primary-3" = theme.acc.p."3";
    "accent-primary-4" = theme.acc.p."4";
    "accent-primary-5" = theme.acc.p."5";
    "accent-primary-6" = theme.acc.p."6";
    "accent-primary-7" = theme.acc.p."7";
    "accent-primary-8" = theme.acc.p."8";
    "accent-primary-9" = theme.acc.p."9";
    "accent-secondary-1" = theme.acc.s."1";
    "accent-secondary-2" = theme.acc.s."2";
    "accent-secondary-3" = theme.acc.s."3";
    "accent-secondary-4" = theme.acc.s."4";
    "accent-secondary-5" = theme.acc.s."5";
    "accent-secondary-6" = theme.acc.s."6";
    "accent-secondary-7" = theme.acc.s."7";
    "accent-secondary-8" = theme.acc.s."8";
    "accent-secondary-9" = theme.acc.s."9";

    "alias-background" = theme.aliases.background;
    "alias-off-background" = theme.aliases.offBackground;
    "alias-selection" = theme.aliases.selection;
    "alias-foreground" = theme.aliases.foreground;
    "alias-muted" = theme.aliases.muted;
    "alias-accent" = theme.aliases.accent;
    "alias-accent-hover" = theme.aliases.accentHover;

    "ui-font-family" = theme.ui.fontFamily;
    "ui-code-font-family" = theme.ui.codeFontFamily;
    "ui-font-size" = theme.ui.fontSize;
    "ui-line-height" = theme.ui.lineHeight;
    "ui-letter-spacing" = theme.ui.letterSpacing;
    "ui-gap" = theme.ui.gap;
    "ui-panel-padding" = theme.ui.panelPadding;
    "ui-row-height" = theme.ui.rowHeight;
    "ui-radius" = theme.ui.radius;
    "ui-border-width" = theme.ui.borderWidth;
    "ui-success" = theme.ui.success;
    "ui-warning" = theme.ui.warning;
    "ui-error" = theme.ui.error;
    "ui-info" = theme.ui.info;

    "syntax-background" = theme.syntax.background;
    "syntax-foreground" = theme.syntax.foreground;
    "syntax-comment" = theme.syntax.comment;
    "syntax-keyword" = theme.syntax.keyword;
    "syntax-string" = theme.syntax.string;
    "syntax-number" = theme.syntax.number;
    "syntax-function" = theme.syntax.function;
    "syntax-variable" = theme.syntax.variable;
    "syntax-type" = theme.syntax.type;
    "syntax-operator" = theme.syntax.operator;
    "syntax-constant" = theme.syntax.constant;
    "syntax-exception" = theme.syntax.exception;

    "markup-heading" = theme.markup.heading;
    "markup-link" = theme.markup.link;
    "markup-emphasis" = theme.markup.emphasis;
    "markup-strong" = theme.markup.strong;
    "markup-code" = theme.markup.code;
    "markup-quote" = theme.markup.quote;
    "markup-muted" = theme.markup.muted;

    "diff-added" = theme.diff.added;
    "diff-added-background" = theme.diff.addedBackground;
    "diff-removed" = theme.diff.removed;
    "diff-removed-background" = theme.diff.removedBackground;
    "diff-modified" = theme.diff.modified;
    "diff-modified-background" = theme.diff.modifiedBackground;
    "diff-line-number" = theme.diff.lineNumber;
    "diff-line-number-active" = theme.diff.lineNumberActive;
  };
}
