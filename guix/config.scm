(use-modules
 (gnu)
 ((gnu packages admin) #:select (htop inetutils tree))
 ((gnu packages base) #:select (glibc-utf8-locales))
 ((gnu packages certs) #:select (nss-certs))
 ((gnu packages cups) #:select (cups-filters hplib-minimal))
 ((gnu packages curl) #:select (curl))
 ((gnu packages docker) #:select (docker-cli))
 ((gnu packages emacs) #:select (emacs))
 ((gnu packages emacs) #:select (emacs))
 ((gnu packages fonts)
  #:select (font-adobe-source-code-pro
            font-iosevka
            font-tamzen))
 ((gnu packages fontutils) #:select (fontconfig))
 ((gnu packages gl) #:select (mesa))
 ((gnu packages gnupg) #:select (gnupg))
 ((gnu packages linux)
  #:select (bluez
            iproute
            light
            linux-libre-with-bpf))
 ((gnu packages ncurses) #:select (ncurses))
 ((gnu packages package-management) #:select (nix nix-unstable))
 ((gnu packages shells) #:select (fish))
 ((gnu packages shellutils) #:select (fzy))
 ((gnu packages ssh) #:select (openssh))
 ((gnu packages suckless) #:select (slock))
 ((gnu packages tmux) #:select (tmux))
 ((gnu packages version-control) #:select (git))
 ((gnu packages vim) #:select (neovim))
 ((gnu packages vpn) #:select (wireguard-tools))
 ((gnu packages web-browsers) #:select (lynx))
 ((gnu packages xdisorg) #:select (xcape xlockmore))
 ((gnu packages xorg)
  #:select (xkbcomp
            xinit
            xorg-server
            xkeyboard-config))
 (gnu services)
 ((gnu services base)
  #:select (gpm-service-type
            gpm-configuration))
 ((gnu services cups)
  #:select (cups-service-type
            cups-configuration))
 ((gnu services dbus)
  #:select (dbus-service))
 ((gnu services desktop)
  #:select (bluetooth-service
            %desktop-services
            fontconfig-file-system-service
            elogind-service-type
            polkit-wheel-service
            cups-pk-helper-service-type
            udisks-service
            x11-socket-directory-service))
 ((gnu services dns)
  #:select (dnsmasq-service-type
            dnsmasq-configuration))
 (gnu services docker)
 ((gnu services networking)
  #:select (network-manager-service-type
            network-manager-configuration
            ntp-service-type
            usb-modeswitch-service-type
            wpa-supplicant-service-type))
 ((gnu services nix)
  #:select (nix-service-type nix-configuration))
 ((gnu services pm)
  #:select (thermald-configuration
            thermald-service-type
            tlp-configuration
            tlp-service-type))
 ((gnu services shepherd)
  #:select (shepherd-service
            shepherd-service-type))
 ((gnu services ssh)
  #:select (openssh-service-type
            openssh-configuration))
 ;; ((gnu services xdisorg)
 ;;  #:select (xcape-configuration
 ;;            xcape-service-type))
 ((gnu services sound)
  #:select (alsa-service-type))
 ((gnu services virtualization)
  #:select (qemu-binfmt-service-type
            qemu-binfmt-configuration
            lookup-qemu-platforms))
 (gnu services xorg)
 (guix gexp)
 (ice-9 match))

(define ctrl-nocaps (keyboard-layout "de" #:options '("ctrl:nocaps") #:model "thinkpad"))

(define xorg-conf
  (xorg-configuration
   (keyboard-layout ctrl-nocaps)
   (server-arguments
    `("-keeptty" ,@%default-xorg-server-arguments))))

(define startx
  (program-file
   "startx"
   #~(begin
       (setenv
        "XORG_DRI_DRIVER_PATH" (string-append #$mesa "/lib/dri"))
       (setenv
        "XKB_BINDIR" (string-append #$xkbcomp "/bin"))

       ;; X doesn't accept absolute paths when run with suid
       (apply
        execl
        (string-append #$xorg-server "/bin/X")
        (string-append #$xorg-server "/bin/X")
        "-config" #$(xorg-configuration->file xorg-conf)
        "-configdir" #$(xorg-configuration-directory
                        (xorg-configuration-modules xorg-conf))
        "-logverbose" "-verbose" "-terminate"
        (append '#$(xorg-configuration-server-arguments xorg-conf)
                (cdr (command-line)))))))

(define tamzen-psf-font
  (file-append
   font-tamzen "/share/kbd/consolefonts/TamzenForPowerline10x20.psf"))
(define chown-program-service-type
  (service-type
   (name 'chown-program-service-type)
   (extensions
    (list
     (service-extension setuid-program-service-type (const '()))
     (service-extension
      activation-service-type
      (lambda (params)
        #~(begin
            (define (chownership prog user group perm)
              (let ((uid (passwd:uid (getpw user)))
                    (gid (group:gid (getgr group))))
                (chown prog uid gid)
                (chmod prog perm)))
            (for-each (lambda (x) (apply chownership x)) #$params))))))
   (description "Modify permissions and ownership of programs.")))

(define my-services
  (cons*
    ;; TODO: Add service for modprobe.d modules?
    (bluetooth-service #:auto-enable? #t)
    (service alsa-service-type)
    (service cups-pk-helper-service-type)
    (service cups-service-type
             (cups-configuration
              (web-interface? #t)
              (extensions
               `(,cups-filters ,hplip-minimal))
              (browsing? #t)))
    (service dnsmasq-service-type
             (dnsmasq-configuration
              (servers '("1.1.1.1"))))
    (service docker-service-type)
    (dbus-service)
    (service elogind-service-type)
    fontconfig-file-system-service
    (service nix-service-type
             (nix-configuration
              (package nix)
              (extra-config '("keep-derivations = true"
                              "keep-outputs = true"))))
    (service kmscon-service-type
             (kmscon-configuration
              (virtual-terminal "tty8")
              ;; (scrollback "100000")
              ;; (font-name "'Fantasque Sans Mono'")
              ;; (font-size "15")
              ;; (xkb-layout "us")
              ;; (xkb-variant "")
              ;; (xkb-options "ctrl:nocaps")
              ))
    (service mingetty-service-type (mingetty-configuration
                                    (tty "tty7")))
    (service network-manager-service-type)
    (service ntp-service-type)
    (service openssh-service-type
             (openssh-configuration
              (challenge-response-authentication? #f)
              (password-authentication? #f)))
    polkit-wheel-service
    (service thermald-service-type
             (thermald-configuration))
    (service tlp-service-type
             (tlp-configuration
              (tlp-default-mode "BAT")
              (usb-autosuspend? #f)))
    (service gpm-service-type (gpm-configuration))
    (service qemu-binfmt-service-type
             (qemu-binfmt-configuration
              (platforms
               (lookup-qemu-platforms "arm" "aarch64" "mips64el"))))
    (udisks-service)
    (service usb-modeswitch-service-type)
    (service wpa-supplicant-service-type)

    (screen-locker-service slock)
    (screen-locker-service xlockmore "xlock")

    ;; The following two are for xorg without display manager
    x11-socket-directory-service
    (service
     chown-program-service-type
     #~(list
        (list
         (string-append "/run/setuid-programs/" (basename #$startx))
         "john" "input" #o2755)
        '("/run/setuid-programs/X" "john" "input" #o2755)))
    (modify-services %base-services
      (udev-service-type
       c =>
       (udev-configuration
        (inherit c)
        (rules
         `(,light ; Use light without sudo
           ,(udev-rule ; For xorg sans display manager (gentoo wiki)
             "99-dev-input-group.rules"
             "SUBSYSTEM==\"input\", ACTION==\"add\", GROUP=\"input\"")
           ,@(udev-configuration-rules c)))))
      (console-font-service-type
       s =>
       (map
        (match-lambda ((tty . font) `(,tty . ,tamzen-psf-font)))
        s)))))

(operating-system
  (host-name "faulobst")
  (timezone "Europe/Berlin")
  (locale "de_DE.utf8")
  (keyboard-layout ctrl-nocaps)
  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (target "/boot/efi")
    (keyboard-layout ctrl-nocaps)))
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
    (firmware
     (cons* iwlwifi-firmware
          ibt-hw-firmware
          %base-firmware))
    (initrd
     (lambda
       (file-systems . rest)
     (apply microcode-initrd file-systems
            #:initrd base-initrd
            #:microcode-packages
            (list intel-microcode)
            rest)))
  (mapped-devices
   (list (mapped-device
          (source (uuid "8eea6fdf-d257-41f0-a9f5-eb521f606c26"))
          (target "system-root")
          (type luks-device-mapping))))
  (file-systems
    (cons* (file-system
             (mount-point "/boot/efi")
             (device (uuid "B64E-A856" 'fat))
             (type "vfat"))
           (file-system
             (mount-point "/")
             (device (file-system-label "system-root"))
             (type "ext4")
             (dependencies mapped-devices))
           %base-file-systems))
  (users
   `(,(user-account
       (name "cr0c0")
       (comment "Who cares")
       (group "users")
       (supplementary-groups
        '("wheel" "netdev" "audio" "video" "lp"))
       (home-directory "/home/cr0c0")
       (shell (file-append fish "/bin/fish")))
     ,@%base-user-accounts))
  (packages
   `(;; for HTTPS access
     ,curl ,nss-certs
     ;; essentials
     ,iproute ,git ,openssh ,gnupg ,ncurses
     ;; ???
     ,glibc-utf8-locales
     ;; text editors
     ,neovim ,emacs-no-x
     ;; for keyboards
     ,bluez
     ;; backlight config
     ,light
     ,@%base-packages))
  (setuid-programs
   `(,(file-append docker-cli "/bin/docker")
     ;; Stuff for xorg without display manager.
     ;; startx and X need to be in setuid-programs.
     ;; They also need extra tweaks in the chown-file service below.
     ,(file-append xorg-server "/bin/X")
     ,startx
     ,@%setuid-programs))
  (services my-services)
  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
