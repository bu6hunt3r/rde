;; NOTE: This file is generated from ~/.dotfiles/System.org.  Please see commentary there.

(define-module (faulobst)
  #:use-module (base-system)
  #:use-module (gnu))

(operating-system
 (inherit base-operating-system)
 (host-name "faulobst")

  (mapped-devices
   (list (mapped-device
          (source (uuid "8eea6fdf-d257-41f0-a9f5-eb521f606c26"))
          (target "system-root")
          (type luks-device-mapping))))

  ;; Assume the target root file system is labelled "my-root",
  ;; and the EFI System Partition has UUID 1234-ABCD.
  (file-systems (append
                 (list (file-system
                         (device (file-system-label "system-root"))
                         (mount-point "/")
                         (type "ext4")
                         (dependencies mapped-devices))
                       (file-system
                         (device (uuid "B64E-A856" 'fat))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems)))
