(require 'use-package)

;; Themes
(use-package leuven-theme
  :pin melpa
  )
(use-package tao-theme :defer t)

(load-theme 'leuven)

;; Disable all themes when loading a new one.
(defadvice load-theme (before theme-dont-propagate activate)
  (mapcar #'disable-theme custom-enabled-themes))

;; Fonts
(add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono"))
(set-face-attribute 'default nil
;;                    :font "DejaVu Sans Mono" ;; This breaks if Emacs is started as a daemon
                    :height (if (string-prefix-p  "rudiger" system-name) 120 100)
                    )

;; Smooth(er) scrolling
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)) ;; one line at a time
      mouse-wheel-progressive-speed nil ;; don't accelerate scrolling
      mouse-wheel-follow-mouse 't ;; scroll window under mouse
    
      scroll-step 1 ;; keyboard scroll one line at a time
      )

;; UI elements

(unless (string= 'system-type 'darwin) (menu-bar-mode -1))
(tool-bar-mode -1)
(scroll-bar-mode -1)

(use-package discover-my-major)

(use-package hydra)

(use-package recentf
  :init (recentf-mode)
  )

(use-package windmove
  :init (windmove-default-keybindings)
  )

(defun startup-echo-area-message ()
  "I'm ready!") ; Because SpongeBob.

(provide 'setup-ui)
