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
       (nix +lsp)

       :tools
       (lsp +eglot)

       :config
       (default +bindings +smartparens))
