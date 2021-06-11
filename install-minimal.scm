;; This is an operating system configuration template
;; for a "desktop" setup without full-blown desktop
;; environments.

(use-modules (gnu) (gnu system nss))
(use-modules (nongnu packages linux) 
             (nongnu system linux-initrd)
             (srfi srfi-1)
             (guix channels)
             (guix inferior))

(use-service-modules desktop xorg)
(use-package-modules bootloaders certs emacs emacs-xyz ratpoison suckless wm
                     xorg)

(operating-system
  (host-name "faulobst")
  (timezone "Europe/Berlin")
  (locale "de_DE.utf8")

  (kernel
   (let*
       ((channels
         (list (channel
                (name 'nonguix)
                (url "https://gitlab.com/nonguix/nonguix")
                (commit "9f0740a1ad240a009f764a211c76c2d3cb056677"))
               (channel
                (name 'guix)
                (url "https://git.savannah.gnu.org/git/guix.git")
                (commit "bd32bcca56ae4a27e754e43ace9bf28b0cae298e"))
               ))
        (inferior
         (inferior-for-channels channels)))
     (first (lookup-inferior-packages inferior "linux" "5.12.6"))))
  (initrd
   (lambda
       (file-systems . rest)
     (apply microcode-initrd file-systems
            #:initrd base-initrd
            #:microcode-packages
            (list intel-microcode)
            rest)))
  (firmware
   (cons* iwlwifi-firmware
          ibt-hw-firmware
          %base-firmware))

  (kernel-arguments '("quiet" "modprobe.blacklist=pcspkr,snd_pcsp" "net.ifnames=0"))

  (keyboard-layout (keyboard-layout "de" #:model "thinkpad"))

  ;; Use the UEFI variant of GRUB with the EFI System
  ;; Partition mounted on /boot/efi.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (target "/boot/efi")))

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
                 %base-file-systems))

  (users (cons (user-account
                (name "cr0c0")
                (comment "Myself")
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  ;; Add a bunch of window managers; we can choose one at
  ;; the log-in screen with F1.
  (packages (append (list
                     ;; window managers
                     ratpoison i3-wm i3status dmenu
                     emacs emacs-exwm emacs-desktop-environment
                     ;; terminal emulator
                     xterm
                     ;; for HTTPS access
                     nss-certs)
                    %base-packages))

  ;; Use the "desktop" services, which include the X11
  ;; log-in service, networking with NetworkManager, and more.
  (services (cons (set-xorg-configuration
                     (xorg-configuration
                       (keyboard-layout keyboard-layout))) 
                   %desktop-services))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
