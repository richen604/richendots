;;; init.el -*- lexical-binding: t; -*-

(doom! :completion
       vertico

       :ui
       doom
       dashboard
       modeline
       nav-flash
       ophints
       (popup +defaults)
       window-select

       :editor
       evil

       :emacs
       undo

       :term
       eshell
       vterm

       :os
       (tty +osc)

       :lang
       emacs-lisp
       (nix +lsp +tree-sitter)
       (org +pretty)
       markdown
       sh
       (javascript +lsp +tree-sitter)
       (web +lsp +tree-sitter)
       (json +lsp +tree-sitter)
       (yaml +lsp +tree-sitter)

       :tools
       (lsp +eglot)
       tree-sitter

       :config
       (default +bindings +smartparens))
