
;; THIS FILE IS TANGLED FROM AN ORG FILE! DO NOT EDIT!

(package-initialize)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/"))

(blink-cursor-mode 0)

(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(setq-default indicate-buffer-boundaries 'left)
(setq-default indicate-empty-lines t)

(show-paren-mode t)
(set-face-background 'show-paren-mismatch-face "red")
(set-face-background 'show-paren-match-face "#f0f0f0")
(setq show-paren-style 'expression)

;; Hilight trailing whitespace
;; like this -->   
;;
(setq-default show-trailing-whitespace t)
(set-face-background 'trailing-whitespace "orange1")

(setq compilation-scroll-output t)

(transient-mark-mode t)
(setq mouse-yank-at-point t)

(setq user-mail-address "anders@0x63.nu")
(setq inhibit-startup-screen t)
(setq calendar-week-start-day 1)

(setq aw-default-font "Inconsolata-10")

(defun aw-large-frame ()
  "Create a new fullscreen frame with a larger font (for pair programming/review)"
  (interactive)
  (message "aw-large-frame requires emacs23"))

(when (>= emacs-major-version 23)
  (set-frame-font aw-default-font t)
  (defun aw-new-frame-set-font-function (frame)
    ""
    (with-selected-frame frame
      (set-frame-font aw-default-font nil)))

  (add-hook 'after-make-frame-functions 'aw-new-frame-set-font-function)

  (defun aw-large-frame ()
    "Create a new fullscreen frame with a larger font (for pair programming/review)"
    (interactive)
    (with-selected-frame (make-frame '((name . "Emacs Largefont frame")
                                       (window-system . x)))
      (set-frame-font "Inconsolata-16" t)
      (set-frame-parameter nil 'fullscreen 'fullboth)
      (selected-frame))))

;; headerline contains current function and flymake error on current line
(which-func-mode t)
(setq-default header-line-format
              '(
                (which-func-mode which-func-format)
                (flymake-mode (" " (:eval (aw-flymake-get-err))))
                ))

;;
;; store symbol at point to killring
;;
(defun aw-kill-ring-save-symbol ()
  "Copy the symbol under point to the killring."
  (interactive)
  (let ((b (bounds-of-thing-at-point 'symbol)))
    (kill-ring-save (car b) (cdr b))))

;;
;; Stuff for popping up the yankmenu popup
;;
(defun aw-popup-menu-at-point (menu)
  "Shows popup menu at current point, not where mouse pointer happens to be"
  (let* ((pos (posn-at-point))
         (x (car (posn-x-y pos)))
         (y (cdr (posn-x-y pos)))
         (win (posn-window pos)))
    
    (popup-menu menu (list (list x y) win))))


(defun aw-yankmenu-popup ()
  ""
  (interactive)
  (aw-popup-menu-at-point 'yank-menu))

;; Customizations for woman manual viewer

(require 'woman)

(setq woman-use-own-frame nil)


;; Stuff for grabbing headers from man pages
;;
;; Pressing 'h' in a woman buffer grabs all #include lines and puts them in the kill ring
;;
(defun aw-interesting-beginning-of-line ()
  ""
  (save-excursion
    (beginning-of-line)
    (while (looking-at "[\t ]")
      (forward-char))
    (point)))


(defun aw-interesting-end-of-line ()
  ""
  (save-excursion
    (end-of-line)
    (while (looking-at "[\t ]")
      (backward-char))
    (point)))

(defun aw-current-interesting-line ()
  ""
  (buffer-substring-no-properties
   (aw-interesting-beginning-of-line)
   (aw-interesting-end-of-line)))


(defun aw-grab-includes-from-woman ()
  ""
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (not (looking-at "SYNOPSIS"))
      (forward-line))
    (let ((s ""))
      (while (not (looking-at "DESCRIPTION"))
        (if (looking-at "[         ]*#include")
            (setq s (concat s (aw-current-interesting-line) "\n")))
        (forward-line))
      (kill-new s))))

(defun aw-woman-hook ()
  ""
  (define-key woman-mode-map "h" 'aw-grab-includes-from-woman))

(add-hook 'woman-mode-hook 'aw-woman-hook)

;; customizations for flymake


(require 'flymake)

; no ugly gui warnings when flymake can't be enabled
(setq flymake-gui-warnings-enabled nil)

; some logging
(setq flymake-log-level 0)

(defun aw-flymake-if-buffer-isnt-tramp ()
  (if (not (and (boundp 'tramp-file-name-structure)
                (string-match (car tramp-file-name-structure) (buffer-file-name))))
      (flymake-mode t)))

; enables flymake mode iff buffer has a filename set,
; otherwise things breaks badly for things such as emerge
(defun aw-flymake-if-buffer-has-filename ()
  (if (buffer-file-name)
      (aw-flymake-if-buffer-isnt-tramp)))

(defun aw-flymake-get-err ()
  "Gets first error message for current line"
  (let ((fm-err (car (flymake-find-err-info flymake-err-info (flymake-current-line-no)))))
    (if fm-err
        (flymake-ler-text (nth 0 fm-err)))))

(defun aw-flymake-display-err ()
  (interactive)
  (let ((err (aw-flymake-get-err)))
    (message (format "FLYMAKE: %s" err))))

(defmacro aw-flymake-add-simple (ptrn cmd)
  `(add-to-list 'flymake-allowed-file-name-masks
                (list ,ptrn
                      (lambda ()
                        (let* ((temp-file (flymake-init-create-temp-buffer-copy
                                           'flymake-create-temp-inplace))
                               (local-file (file-relative-name 
                                            temp-file
                                            (file-name-directory buffer-file-name))))
                          (list ,cmd (list local-file)))))))



; enable flymake on c
;(add-hook 'c-mode-hook 'aw-flymake-if-buffer-has-filename t)
; enable flymake on py
;(add-hook 'python-mode-hook 'aw-flymake-if-buffer-has-filename t)

; Or lets do a global enable global enable
(add-hook 'find-file-hook 'aw-flymake-if-buffer-has-filename)

(global-set-key "\M-g" 'goto-line)

(global-set-key "\M-sts" 'tags-search)
(global-set-key "\M-stf" 'aw-ido-find-tag)
(global-set-key "\M-stv" 'visit-tags-file)
(global-set-key "\M-st%" 'tags-query-replace)
(global-set-key "\M-stn" 'tags-loop-continue)

(global-set-key "\M-." 'aw-ido-find-tag)

; Adapted from andre, who probably borrowed it from someone else.
(defun cut-or-kill ()
  "If the mark is active - kill region, otherwise backward-kill-word"
  (interactive)
  (if mark-active
      (kill-region (point) (mark))
    (backward-kill-word 1)))

(global-set-key "\C-w" 'cut-or-kill)

(define-key help-map "a" 'apropos)

(define-key help-map "x" 'describe-text-properties)

; C-x 5 l => create new "large" frame. A fullscreen frame with larger
;            font is nice for pair-programming/review.
(define-key ctl-x-5-map "l" 'aw-large-frame)

; "C-c w" => Add symbol under cursor to kill ring. When programming I
;            often write a call to a new function that I need to write
;            before writing the actual function, and use this to get
;            the name into the key ring for easy paste when writing
;            the actual function.
(global-set-key "\C-cw" 'aw-kill-ring-save-symbol)
(global-set-key "\C-cy" 'aw-yankmenu-popup)
(global-set-key "\C-cn" 'flymake-goto-next-error)
(global-set-key "\C-cd" 'dictionary-search)

(global-set-key "\C-cg" 'aw-ido-imenu-goto)

; The orgtbl is really nice, make it easy to enable it on demand
(global-set-key "\C-ct" 'orgtbl-mode)

; I use untabify often enough to warrant it on a key, and lets use my
; variant that untabifies up to end of line if there is no region.
(defun aw-untabify-region-or-to-eol ()
  (interactive)
  (if mark-active
      (untabify (region-beginning) (region-end))
    (untabify (point) (point-at-eol))))
(global-set-key "\C-cu" 'aw-untabify-region-or-to-eol)


(defun aw-ensure-python-buffer-visible ()
  (interactive)
  (if python-buffer
      (switch-to-buffer-other-window python-buffer t)
    (message "No python buffer available")))

(defun aw-ensure-interesting-buffer-visible ()
  (interactive)
  (if (derived-mode-p 'python-mode)
      (aw-ensure-python-buffer-visible)
    (message "Don't know about interesting buffers for this mode")))

(global-set-key "\C-ci" 'aw-ensure-interesting-buffer-visible)

(defun aw-str-isprefixp (str prefix)
  ""
  (let ((plen (length prefix)))
    (and (>= (length str) plen)
         (string-equal prefix (substring str 0 plen)))))

(defun aw-as-autostyles ()
  ""
  (let (res)
    (dolist (stylename (mapcar 'car c-style-alist) res)
      (if (aw-str-isprefixp stylename "auto-")
          (setq res (cons (substring stylename 5) res))))))

(defun aw-list-str-match (lst x)
  "Return first matching entry in list of patterns"
  (if lst
      (if (string-match (car lst) x)
          (car lst)
        (aw-list-str-match (cdr lst) x))))

(defun aw-as-find-match (matches p)
  ""
  (if p
      (or
       (aw-list-str-match matches (car p))
       (aw-as-find-match matches (cdr p)))))

(defun aw-as-hook ()
  ""
  (message (format "Looking for style for %s" (buffer-file-name)))
  (let ((x (aw-as-find-match (aw-as-autostyles) (split-string (buffer-file-name)))))
    (when x
      (message "Using C style %s" x)
      (c-set-style (concat "auto-" x)))))



; This is based on the trick described here: http://www.emacswiki.org/emacs/SmartTabs
; but instead of macros-generating-advices it uses the indent-line-function variable
(defun aw-c-smarttab-indent-line-function ()
  (cond
   (indent-tabs-mode
    (let ((c-basic-offset fill-column)
          (tab-width fill-column))
      (c-indent-line)))
   (t (c-indent-line))))

;
(c-add-style "aw-base"
             '("linux"
               (tab-width . 4)
               (c-basic-offset . 4)
               (c-offsets-alist . ((case-label . +)))
               (indent-line-function . aw-c-smarttab-indent-line-function)
               ))



;;

(c-add-style "auto-packetlogic2*"
             '("aw-base"))

; use a strange offset to catch indentation errors.
(c-add-style "auto-xmms2*"
             '("aw-base"
               (tab-width . 5)
               (c-basic-offset . 5)))

(c-add-style "auto-kernel*"
             '("linux"))

(c-add-style "auto-/*"
             '("aw-base"))

(add-hook 'c-mode-hook 'aw-as-hook)

; enable flyspell in C sources.
(add-hook 'c-mode-hook 'flyspell-prog-mode t)

(require 'uniquify)

; server/src/foo.c client/src/foo.c
; =>
; foo.c<server>    foo.c<client>
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-strip-common-suffix t)

; Rename buffers on close.
(setq uniquify-after-kill-buffer-p t)


; Don't try to be clever on *buffers*
(setq uniquify-ignore-buffers-re "^\\*")

(add-hook 'python-mode-hook 'flyspell-prog-mode t)

; waf's wscript files are python
(add-to-list 'auto-mode-alist '("wscript" . python-mode))

; Add align rules for python dicts.
; e.g allow using "C-u M-x align" to get pretty things like:
; mydict = {
;     a:        10,
;     bbbbbb:   20,
;     ccc:      30,
; }
(require 'align)
(add-to-list 'align-rules-list '(python-dict
                                 (regexp . ":\\(\\s-*\\)[^#\t\n ]")
                                 (modes . (python-mode))))



; some debian startup file adds pylint-python-hook that is broken on my system
(remove-hook 'python-mode-hook 'pylint-python-hook)


;; use pyflakes to check .py files.
(aw-flymake-add-simple "\\.py\\'" "pyflakes")
;; and pyrexc to check .pyx files.
(aw-flymake-add-simple "\\.pyx\\'" "pyrexc")



(defun aw-py-docstr-p ()
  (save-excursion
    (and (python-beginning-of-string)
         (looking-at "\"\"\""))))


(defun aw-py-docstr-indent-previous-paragraph-indent-amout (start default)
  (catch 'done
    (while (looking-at "^[[:blank:]]*$")
      (if (> (point) start)
          (throw 'done default))
      (forward-line -1))
    (while (not (looking-at "^[[:blank:]]*$"))
      (if (> (point) start)
          (throw 'done default))
      (forward-line -1))
    (forward-line 1)
    (throw 'done (current-indentation))))

(defun aw-py-docstr-indent-amount ()
  (save-excursion
    (let* ((T (save-excursion
                (python-beginning-of-string)
                (cons (point) (current-column))))
           (start (car T))
           (indent (cdr T)))
      (forward-line 0)
      (if (looking-at "^[[:blank:]]*@.+: *")
          indent
        (forward-line -1)
        (cond
         ;; first line - use same indent as multiline string itself
         ((< (point) start) indent)

         ;; epydoc field - indent up to colon
         ((looking-at "^[[:blank:]]*@.+: *")
          (save-excursion
            (goto-char (match-end 0))
            (current-column)))

         ;; blank line - find previous nonblank
         ((looking-at "^[[:blank:]]*$")
          (aw-py-docstr-indent-previous-paragraph-indent-amout start indent))

         ;; default - same as previous line
         (t (current-indentation)))))))


(defun aw-py-docstr-indent-line-function ()
  (if (not (aw-py-docstr-p))
      (python-indent-line)
    (indent-line-to (aw-py-docstr-indent-amount))))

(defun aw-py-docstr-fill-paragraph (&optional justify region)
  ""
  (interactive)
  (let ((paragraph-separate "[ \t\\f]*\\(@.*\\|\"\"\"[ \t\\f]*\\)?$")
        (paragraph-start "[ \t\\f]*\\(@.*\\|\"\"\"[ \t\\f]*\\)?$"))
    (python-fill-paragraph)))


(add-hook 'python-mode-hook
          (lambda ()
            ;; I hope we can trust that these already are local...
            (setq indent-line-function 'aw-py-docstr-indent-line-function)
            (setq fill-paragraph-function 'aw-py-docstr-fill-paragraph))
          t)

; ido is really nice for finding files and buffer switching

; Don't keep state between emacs invocations
; (needs to be set before enabling ido-mode)
(setq ido-save-directory-list-file nil)


(require 'ido)
(ido-mode t)


; make sure .pyx/.y/.l files comes before their C file friends.
(setq ido-file-extensions-order '(".pyx" ".y" ".l" t))



(defun aw-ido-completing-read-with-default (prompt entries predicate)
  (let* ((maybedft (find-tag-default))
         (compl (all-completions "" entries predicate))
         (dft (assoc-string maybedft compl)))
    (ido-completing-read
            prompt
            compl
            nil
            t
            nil
            nil
            dft)))


(defun aw-ido-find-tag ()
  (interactive)
  (find-tag (aw-ido-completing-read-with-default "Tag: " (tags-lazy-completion-table) nil)))

;; There are entries with negative indices (to force rescan), remove them.
(defun aw-imenu-entry-valid-p (x)
  (if (number-or-marker-p (cdr x))
      (< 0 (cdr x))
    t))

(defun aw-ido-imenu-goto ()
  (interactive)
  (let ((imenu-auto-rescan t))
    (imenu (aw-ido-completing-read-with-default "Index item: " (imenu--make-index-alist) 'aw-imenu-entry-valid-p))))

(defun aw-git-rebase-todo-change-action ()
  ""
  (interactive)
  (save-excursion
    (beginning-of-line)
    (cond
     ((looking-at "pick ") (replace-match "reword "))
     ((looking-at "reword ") (replace-match "squash "))
     ((looking-at "squash ") (replace-match "edit "))
     ((looking-at "edit ") (replace-match "fixup "))
     ((looking-at "fixup ") (replace-match "pick ")))))

(defun aw-git-rebase-get-sha ()
  ""
  (interactive)
  (save-excursion
    (beginning-of-line)
    (forward-word)
    (forward-word)
    (current-word)))


(defun aw-git-rebase-show ()
  (interactive)
  (let ((sha (aw-git-rebase-get-sha)))
    (with-current-buffer (get-buffer-create "*git-rebase-todo diff*")
      (display-buffer (current-buffer) t)
      (erase-buffer)
      (call-process "git" nil (current-buffer) t "show" sha)
      (diff-mode))))

(defun aw-git-rebase-todo-mode-setup ()
  (setq aw-git-rebase-todo-mode-keymap (make-sparse-keymap))
  (define-key aw-git-rebase-todo-mode-keymap " " 'aw-git-rebase-todo-change-action)
  (define-key aw-git-rebase-todo-mode-keymap (kbd "RET") 'aw-git-rebase-show)
  (use-local-map aw-git-rebase-todo-mode-keymap))

(define-generic-mode aw-git-rebase-todo-mode
  '("#")                                     ; comments
  '("pick" "reword" "squash" "edit" "fixup") ; keywords
  nil                                        ; fontlock words
  '(".*/git-rebase-todo")                    ; mode-alist
  '(aw-git-rebase-todo-mode-setup)           ; function list
  "git rebase -i todo list mode")            ; docstring

(defun aw-git-fast-import--insert-one-file (filalist)
  (let ((f (car filalist))
        (rest (cdr filalist)))
    (let ((path (car f))
          (data (cdr f)))
      (insert "M 100644 inline " path "\n")
      (if (bufferp data)
          (insert "data " (number-to-string (buffer-size data)) "\n"
                  (with-current-buffer data
                    (buffer-string)) "\n")
        (insert "data " (number-to-string (length data)) "\n" data "\n")))
    (when rest
      (aw-git-fast-import--insert-one-file rest))))

(defun aw-git-fast-import (branch initial commitmsg filalist)
  "Create one commit on specified branch containing specified files"
  (with-temp-buffer
    (insert "commit " branch "\n")
    (insert "committer " user-full-name " <" user-mail-address "> now\n")
    (insert "data " (number-to-string (length commitmsg)) "\n" commitmsg "\n")
    (unless initial
      (insert "from " branch "^0\n"))
    (insert "deleteall\n")
    (aw-git-fast-import--insert-one-file filalist)
    (insert "done\n")
    (shell-command-on-region (point-min) (point-max) "git fast-import --date-format=now --done")))

(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-hook 'org-mode-hook 'flyspell-prog-mode t)

(defun aw-dot-emacs-export-to-git ()
  (interactive)
  (org-babel-tangle)
  (let ((html (org-export-as-html 3 nil nil 'string))
        (initel (with-temp-buffer
                  (insert-file-contents "~/.emacs.d/init.el")
                  (buffer-string))))
    (aw-git-fast-import "refs/heads/export" nil "export commit" `(("index.html" . ,html)
                                                                  ("init.el" . ,initel)))))
