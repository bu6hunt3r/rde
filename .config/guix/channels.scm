;; -*- geiser-scheme-implementation: guile -*-
(list (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (commit
          "7ff515aa511afbaf177a8bde68bde6a3878ca447")
        (introduction
          (make-channel-introduction
            "9edb3f66fd807b096b48283debdcddccfea34bad"
            (openpgp-fingerprint
              "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
       (name 'flat)
       (url "https://github.com/flatwhatson/guix-channel.git")
       (introduction
        (make-channel-introduction
         "33f86a4b48205c0dc19d7c036c85393f0766f806"
         (openpgp-fingerprint
          "736A C00E 1254 378B A982  7AF6 9DBE 8265 81B6 4490"))))
      (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        (commit
          "22cb4bb981ab9da9b8c0bba32c3198d31c0544b4")))

(cons* (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix"))
       (channel
        (name 'flat)
        (url "https://github.com/flatwhatson/guix-channel.git"))
       %default-channels)
