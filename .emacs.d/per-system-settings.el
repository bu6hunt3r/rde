(require 'map) ;; Needed for map-merge

(setq dw/system-settings
  (map-merge
    'list
    '((desktop/dpi . 180)
      (desktop/background . "samuel-ferrara-uOi3lg8fGl4-unsplash.jpg")
      (emacs/default-face-size . 100)
      (emacs/variable-face-size . 100)
      (emacs/fixed-face-size . 100)
      (polybar/height . 10)
      (polybar/font-0-size . 18)
      (polybar/font-1-size . 14)
      (polybar/font-2-size . 20)
      (polybar/font-3-size . 13)
      (dunst/font-size . 20)
      (dunst/max-icon-size . 88)
      (vimb/default-zoom . 180)
      (qutebrowser/default-zoom . 200))
    
    (when (equal system-name "faulobst")
      '((desktop/dpi . 240)
        (polybar/height . 40)
        (vimb/default-zoom . 200)))
    ))
