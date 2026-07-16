;;; config.el -*- lexical-binding: t; -*-

(add-to-list 'custom-theme-load-path (expand-file-name "themes" doom-user-dir))

(setq user-full-name "Richen"
      doom-theme 'grove
      display-line-numbers-type 'relative)

(after! which-key
  (setq which-key-idle-delay 0.5))
