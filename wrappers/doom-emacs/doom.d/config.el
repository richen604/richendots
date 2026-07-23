;;; config.el -*- lexical-binding: t; -*-

(add-to-list 'custom-theme-load-path (expand-file-name "themes" doom-user-dir))

(setq user-full-name "Richen"
      doom-theme 'grove
      display-line-numbers-type 'relative)

;; Doom removes direct tree-sitter mode associations, but TypeScript has no
;; fallback mode when :lang javascript uses +tree-sitter.
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[tj]sx\\'" . tsx-ts-mode))

(after! which-key
  (setq which-key-idle-delay 0.5))
