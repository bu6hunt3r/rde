;; This is an operating system configuration template for a "wayland"
;; setup with sway, emacs-pgtk and ungoogled-chromium where the root
;; partition is encrypted with LUKS.

(define-module (rde system desktop)
  #:use-module (gnu system)
  ;; #:use-module (rde packages)
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages bootloaders)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu system keyboard)
  #:use-module ((gnu system install) #:prefix gnu-system-install:)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system accounts)
  #:use-module (gnu system shadow)
  #:use-module (gnu system pam)
  #:use-module (gnu system nss)
  #:use-module (gnu system mapped-devices)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services xorg)
  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (gnu services sddm)
  #:use-module (gnu services dbus)
  #:use-module (gnu services security-token)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)
  #:export (os))

(define os
  (operating-system
   (host-name "faulobst")
   (time-zone "Europe/Berlin")
   (locale "de_DE.utf8")

   (keyboard-layout
    (keyboard-layout "de"))
   (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (target "/dev/sda1")
                (keyboard-layout keyboard-layout)))

   (mapped-devices (list (mapped-device
                          (source (uuid ""))
                          (target "enc")
                          (type luks-device-mapping))))

   (file-systems
    (append
     (list (file-system
            (device (file-system-label "enc"))
            (mount-point "/")
            (type "ext4")
            (dependencies mapped-devices)))
     %base-file-systems))

   (users (cons (user-account
                 (name "cr0c0")
                 (comment "myself")
                 (password (crypt "123456" "$6$"))
                 (group "users")
                 (supplementary-groups '("wheel" "netdev"
                                         "audio" "video")))
                %base-user-accounts))
   (packages (append
              (map specification->package+output
                   '(;; System packages
                     "nss-certs"))
              %base-package-disk-utilities
              %base-packages))
   (services
    (append
     (list
      (simple-service 'switch-to-tty2 shepherd-root-service-type
                      (list (shepherd-service
                             (provision '(kbd))
                             (requirement '(virtual-terminal))
                             (start #~(lambda ()
                                        (invoke #$(file-append kbd "/bin/chvt") "2")))
                             (respawn? #f))))
      (service pcscd-service-type)
      (screen-locker-service swaylock "swaylock")
      (udev-rules-service
       'backlight
       (file->udev-rule "90-backlight.rules"
                        (file-append light "/lib/udev/rules.d/90-backlight.rules")))
      (remove (lambda (service)
                (member (service-kind service)
                        (list gdm-service-type
                              screen-locker-service-type)))
              %desktop-services)))))

  os
