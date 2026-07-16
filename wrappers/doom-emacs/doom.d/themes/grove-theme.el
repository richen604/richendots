;;; grove-theme.el --- Grove theme for Doom Emacs -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;; Code:

(require 'doom-themes)

(defgroup grove-theme nil
  "Options for the `grove' theme."
  :group 'doom-themes)

(defcustom grove-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds padding to the mode-line."
  :group 'grove-theme
  :type '(choice integer boolean))

(def-doom-theme grove
  "A dark green theme based on the Grove desktop palette."
  :family 'grove
  :background-mode 'dark

  ((bg         '("#0E120F" "black"       "black"))
   (bg-alt     '("#142825" "black"       "black"))
   (base0      '("#0E120F" "black"       "black"))
   (base1      '("#0E1310" "black"       "black"))
   (base2      '("#10221F" "black"       "black"))
   (base3      '("#142825" "brightblack" "brightblack"))
   (base4      '("#295233" "brightblack" "brightblack"))
   (base5      '("#578F65" "brightblack" "brightblack"))
   (base6      '("#65A37E" "green"       "green"))
   (base7      '("#CCFFE0" "white"       "white"))
   (base8      '("#FFFFFF" "white"       "brightwhite"))
   (fg         '("#FFFFFF" "white"       "brightwhite"))
   (fg-alt     '("#CCFFE0" "white"       "white"))

   (grey       base5)
   (red        '("#CCFFF9" "brightcyan"  "brightcyan"))
   (orange     '("#AAF0E7" "brightcyan"  "brightcyan"))
   (green      '("#9AE6AD" "green"       "green"))
   (teal       '("#9AE6D0" "cyan"        "brightgreen"))
   (yellow     '("#CCFFF7" "brightcyan"  "yellow"))
   (blue       '("#AAF0DC" "green"       "brightblue"))
   (dark-blue  '("#295233" "green"       "blue"))
   (magenta    '("#9AE6D0" "cyan"        "brightmagenta"))
   (violet     '("#AAF0E7" "brightcyan"  "magenta"))
   (cyan       '("#9AE6DA" "cyan"        "brightcyan"))
   (dark-cyan  '("#65A399" "cyan"        "cyan"))

   (highlight      green)
   (vertical-bar   base4)
   (selection      base4)
   (builtin        green)
   (comments       base6)
   (doc-comments   green)
   (constants      cyan)
   (functions      fg-alt)
   (keywords       cyan)
   (methods        teal)
   (operators      base7)
   (type           yellow)
   (strings        green)
   (variables      fg)
   (numbers        violet)
   (region         base4)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    cyan)
   (vc-added       green)
   (vc-deleted     red)

   (modeline-bg     bg-alt)
   (modeline-bg-alt bg)
   (modeline-fg     fg)
   (modeline-fg-alt base6)

   (-modeline-pad
    (when grove-padded-modeline
      (if (integerp grove-padded-modeline) grove-padded-modeline 4))))

  ((cursor :background dark-cyan)
   (hl-line :background bg-alt :extend t)
   ((line-number &override) :foreground base4)
   ((line-number-current-line &override) :foreground fg :background bg-alt)
   (fringe :background bg :foreground base4)
   (isearch :background green :foreground bg :weight 'bold)
   (lazy-highlight :background dark-cyan :foreground fg :weight 'bold)
   ((link &override) :foreground cyan :underline t)
   (minibuffer-prompt :foreground green :weight 'bold)
   (show-paren-match :background base4 :foreground fg :weight 'bold)
   (vertical-border :background bg :foreground base4)

   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-alt :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-alt)))
   (mode-line-emphasis :foreground green :weight 'bold)

   (doom-modeline-bar :background green)
   (doom-modeline-buffer-file :inherit 'mode-line-buffer-id :weight 'bold)
   (doom-modeline-buffer-path :foreground green :weight 'bold)
   (doom-modeline-buffer-project-root :foreground cyan :weight 'bold)
   (doom-modeline-buffer-modified :foreground yellow :weight 'bold)
   (doom-modeline-buffer-major-mode :foreground cyan :weight 'bold)
   (doom-modeline-info :foreground green :weight 'bold)
   (doom-modeline-warning :foreground warning :weight 'bold)
   (doom-modeline-error :foreground error :weight 'bold)

   (vertico-current :background base4 :foreground fg :extend t)
   (completions-common-part :foreground green :weight 'bold)
   (completions-first-difference :foreground cyan :weight 'bold)

   (ansi-color-black :foreground bg :background bg)
   (ansi-color-red :foreground red :background red)
   (ansi-color-green :foreground green :background green)
   (ansi-color-yellow :foreground yellow :background yellow)
   (ansi-color-blue :foreground blue :background blue)
   (ansi-color-magenta :foreground magenta :background magenta)
   (ansi-color-cyan :foreground cyan :background cyan)
   (ansi-color-white :foreground fg :background fg)
   (ansi-color-bright-black :foreground base5 :background base5)
   (ansi-color-bright-red :foreground violet :background violet)
   (ansi-color-bright-green :foreground strings :background strings)
   (ansi-color-bright-yellow :foreground '("#AAF0E5" "brightcyan" "yellow") :background '("#AAF0E5" "brightcyan" "yellow"))
   (ansi-color-bright-blue :foreground blue :background blue)
   (ansi-color-bright-magenta :foreground magenta :background magenta)
   (ansi-color-bright-cyan :foreground cyan :background cyan)
   (ansi-color-bright-white :foreground fg-alt :background fg-alt)
   (vterm-color-default :foreground fg :background bg)
   (vterm-color-black :foreground bg :background bg)
   (vterm-color-red :foreground red :background red)
   (vterm-color-green :foreground green :background green)
   (vterm-color-yellow :foreground yellow :background yellow)
   (vterm-color-blue :foreground blue :background blue)
   (vterm-color-magenta :foreground magenta :background magenta)
   (vterm-color-cyan :foreground cyan :background cyan)
   (vterm-color-white :foreground fg :background fg)

   (eshell-prompt :foreground green :weight 'bold)
   (eshell-ls-directory :foreground green :weight 'bold)
   (eshell-ls-executable :foreground cyan)
   (eshell-ls-symlink :foreground teal :weight 'bold)
   (eshell-ls-archive :foreground yellow)
   (eshell-ls-unreadable :foreground base5)

   (dired-directory :foreground green :weight 'bold)
   (dired-header :foreground cyan :weight 'bold)
   (dired-mark :foreground yellow :weight 'bold)
   (dired-marked :foreground yellow :weight 'bold)
   (dired-symlink :foreground teal :weight 'bold)

   (diff-added :foreground green :background (doom-blend green bg 0.1))
   (diff-changed :foreground cyan :background (doom-blend cyan bg 0.1))
   (diff-removed :foreground red :background (doom-blend red bg 0.1))
   (diff-header :foreground cyan)
   (diff-file-header :foreground green :weight 'bold)
   (diff-hunk-header :background base3 :foreground fg-alt)

   (markdown-header-face :inherit 'bold :foreground green)
   (markdown-header-delimiter-face :foreground base5)
   (markdown-markup-face :foreground base5)
   (markdown-code-face :background base3 :foreground fg-alt)
   (markdown-pre-face :foreground cyan)
   (markdown-blockquote-face :foreground base6 :slant 'italic)
   (markdown-link-face :foreground cyan :underline t)
   (markdown-url-face :foreground teal)

   ((org-block &override) :background base3 :foreground fg-alt)
   ((org-block-background &override) :background base3)
   ((org-block-begin-line &override) :background base3 :foreground base5)
   ((org-block-end-line &override) :background base3 :foreground base5)
   ((org-code &override) :foreground cyan)
   (org-date :foreground teal)
   (org-document-title :foreground green :weight 'bold)
   (org-document-info :foreground fg-alt)
   (org-drawer :foreground base6)
   (org-ellipsis :foreground green :underline nil)
   (org-formula :foreground cyan)
   (org-level-1 :foreground green :weight 'bold)
   (org-level-2 :foreground cyan :weight 'bold)
   (org-level-3 :foreground teal :weight 'bold)
   (org-level-4 :foreground yellow :weight 'bold)
   (org-meta-line :foreground comments)
   (org-quote :background base3 :foreground fg-alt :slant 'italic)
   (org-table :foreground cyan)
   (org-tag :foreground base6 :weight 'normal)
   (org-todo :foreground green :weight 'bold)
   (org-done :foreground base6 :weight 'bold)
   (org-verbatim :foreground yellow)

   (css-property :foreground fg-alt)
   (css-proprietary-property :foreground yellow)
   (css-selector :foreground teal)
   (web-mode-html-tag-face :foreground green)
   (web-mode-html-tag-bracket-face :foreground base6)
   (web-mode-html-attr-name-face :foreground cyan)
   (web-mode-html-attr-value-face :foreground strings)
   (web-mode-json-key-face :foreground green)
   (web-mode-json-context-face :foreground base6)
   (js2-object-property :foreground green)
   (js2-function-param :foreground fg-alt)

   (eglot-highlight-symbol-face :background base4)
   (flymake-error :underline `(:style wave :color ,red))
   (flymake-warning :underline `(:style wave :color ,yellow))
   (flymake-note :underline `(:style wave :color ,green))))

;;; grove-theme.el ends here
