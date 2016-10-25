
;; THIS FILE IS TANGLED FROM AN ORG FILE! DO NOT EDIT!

  (when (or (>= emacs-major-version 24)
            (load (locate-user-emacs-file "package.el") t))
    (package-initialize)
    (add-to-list 'package-archives
                 '("marmalade" . "https://marmalade-repo.org/packages/"))
    (add-to-list 'package-archives
                 '("melpa" . "https://stable-melpa.org/packages/")))

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

(setq aw-default-font "InputMono Light-10")

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

(defun aw-flycheck-error-message-at-point ()
  (car (delq nil
	     (mapcar
	      (lambda (o) (and (overlay-get o 'flycheck-overlay) (flycheck-error-message (overlay-get o 'flycheck-error))))
	      (overlays-at (point))))))


;; headerline contains current function and flycheck error on current line
(which-func-mode t)
(setq-default header-line-format
	      '((which-func-mode which-func-format)
		(flycheck-mode (" " (:eval (aw-flycheck-error-message-at-point))))))

(eval-after-load 'ansi-color
  '(progn
     (setq ansi-color-names-vector
           ["black" "#600" "#060" "#660"
            "#006" "#066" "#606" "white"])
     (setq ansi-color-map (ansi-color-make-color-map))))

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
    (let ((include-lines))
      (while (not (looking-at "DESCRIPTION"))
	(let ((line (aw-current-interesting-line)))
	  (and (string-prefix-p "#include" line)
	       (add-to-list 'include-lines line t)))
	(forward-line))
      (when include-lines
	(kill-new (mapconcat 'identity include-lines "\n"))
	(message "%d #include-lines added to killring" (length include-lines))))))

(defun aw-woman-hook ()
  ""
  (define-key woman-mode-map "h" 'aw-grab-includes-from-woman))

(add-hook 'woman-mode-hook 'aw-woman-hook)

(add-hook 'after-init-hook #'global-flycheck-mode)

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
  (when (buffer-file-name)
    (message (format "Looking for style for %s" (buffer-file-name)))
    (let ((x (aw-as-find-match (aw-as-autostyles) (split-string (buffer-file-name)))))
      (when x
	(message "Using C style %s" x)
	(c-set-style (concat "auto-" x))))))



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

(eval-after-load 'flyspell
  '(when (or (> emacs-major-version 24)
            (and (= emacs-major-version 24) (>= emacs-minor-version 3)))
    (set-face-attribute 'flyspell-incorrect nil
                        :inherit nil
                        :underline '(:color "#cc0000" :style wave))
    (set-face-attribute 'flyspell-duplicate nil
                        :inherit nil
                        :underline '(:color "#00cc00" :style wave))))

(defun aw-directory-shell-buffer-name-mode-func (s)
  (rename-buffer (format "*shell[%s]*" (abbreviate-file-name (directory-file-name default-directory))) t))

(define-minor-mode aw-directory-shell-buffer-name-mode
  ""
  nil nil nil
  (if aw-directory-shell-buffer-name-mode
      (progn
	(aw-directory-shell-buffer-name-mode-func "")
	(add-hook 'comint-input-filter-functions 'aw-directory-shell-buffer-name-mode-func t t))
    (remove-hook 'comint-input-filter-functions 'aw-directory-shell-buffer-name-mode-func t)))

(add-hook 'shell-mode-hook '(lambda () (aw-directory-shell-buffer-name-mode 1)))

(when (require 'bash-completion nil t)
  (bash-completion-setup))

(defun aw-setup-sh-mode ()
  (setq tab-width 8)
  (setq sh-indentation 8)
  (setq sh-basic-offset 8)
  (setq sh-indent-comment t))

(add-hook 'sh-mode-hook 'aw-setup-sh-mode)

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
				 (modes . '(python-mode))))



; some debian startup file adds pylint-python-hook that is broken on my system
(remove-hook 'python-mode-hook 'pylint-python-hook)


(defun aw-py-docstr-p ()
  (let* ((ppss (syntax-ppss))
	 (strbeg (nth 8 ppss)))
    (when strbeg
      (save-excursion
	(goto-char strbeg)
	(looking-at "\"\"\"")))))


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
		(goto-char (nth 8 (syntax-ppss)))
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

(setq ido-save-directory-list-file nil)

(require 'ido)
(ido-mode t)

(setq ido-file-extensions-order '(".pyx" ".y" ".l" t))

(setq ido-default-buffer-method 'selected-window)

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

(defun aw-ido-ucs-insert ()
  (interactive)
  (ucs-insert (cdr (assoc-string (ido-completing-read "Insert: "
                                                      (all-completions "" (ucs-names))
                                                      nil
                                                      t)
                                 (ucs-names)))))

(setq magit-completing-read-function 'magit-ido-completing-read)
(setq git-commit-summary-max-length 70)
(setq magit-process-popup-time 0)
(global-set-key "\C-cm" 'magit-status)

(setenv "GIT_PAGER" "")
(setenv "GIT_EDITOR" "emacsclient")

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
	(insert "data " (number-to-string (string-bytes data)) "\n" data "\n")))
    (when rest
      (aw-git-fast-import--insert-one-file rest))))

(defun aw-git-fast-import (branch initial commitmsg filalist)
  "Create one commit on specified branch containing specified files"
  (with-temp-buffer
    (insert "commit " branch "\n")
    (insert "committer " user-full-name " <" user-mail-address "> now\n")
    (insert "data " (number-to-string (string-bytes commitmsg)) "\n" commitmsg "\n")
    (unless initial
      (insert "from " branch "^0\n"))
    (insert "deleteall\n")
    (aw-git-fast-import--insert-one-file filalist)
    (insert "done\n")
    (shell-command-on-region (point-min) (point-max) "git fast-import --quiet --date-format=now --done")))

(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-hook 'org-mode-hook 'flyspell-prog-mode t)

(setq org-src-preserve-indentation t)

; maybe it is org-edit-src-content-indentation that I'm looking for

(setq
 org-babel-load-languages
 '((sh . t)
   (python . t)
   (emacs-lisp . t)))

(setq org-src-fontify-natively t)

  (defun aw-el-byte-compile-post-tangle ()
    (let ((fn (buffer-file-name)))
      (when (and fn (string-match-p "\\.el$" fn))
        (byte-compile-file fn))))
  
  (add-hook 'org-babel-post-tangle-hook 'aw-el-byte-compile-post-tangle)
  

  (defun aw-org-safe-path-one-safelify (a)
    (replace-regexp-in-string "[^a-zA-Z0-9]" "." (org-no-properties a)))
  (defun aw-org-safe-path ()
    (let ((l (reverse (cons (org-get-heading) (reverse (org-get-outline-path))))))
      (concat (mapconcat 'aw-org-safe-path-one-safelify l "-"))))
  (defun aw-org-set-custom-id ()
    (org-set-property "CUSTOM_ID" (aw-org-safe-path)))
  
  (defun aw-org-set-custom-id-everywhere (backend)
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (outline-next-heading)
        (unless (org-entry-get (point) "CUSTOM_ID")
          (aw-org-set-custom-id)))))

  (add-hook 'org-export-before-parsing-hook 'aw-org-set-custom-id-everywhere)
  

    (defun aw-find-tangle-dest-files ()
      (let ((blocks (org-babel-tangle-collect-blocks))
            res)
        (mapcar (lambda (a)
                  (mapcar (lambda (a)
                            (add-to-list 'res (cdr (assoc :tangle (nth 4 a)))))
                          (cdr a)))
                blocks)
        res))
    
    (defun aw-get-tangle-dest-files ()
      (mapcar (lambda (filepath)
                (cons (file-name-nondirectory filepath)
                      (with-temp-buffer
                        (insert-file-contents filepath)
                        (buffer-string))))
              (aw-find-tangle-dest-files)))
    
    (defun aw-org-tangle-and-export-to-git-branch (&optional allow-create)
      (interactive "P")
      (let ((dd default-directory)
            (tangle-dests (aw-get-tangle-dest-files)))
        (org-babel-tangle)
        (let ((html (org-export-as 'html))
              (extra-files nil))
          (cd dd)
          (aw-git-fast-import "refs/heads/export" allow-create "export commit" `(("index.html" . ,html)
                                                                                 ,@tangle-dests)))))

(defun aw-setup-nxml-mode ()
  (setq indent-tabs-mode nil)
  (setq nxml-child-indent 4))

(add-hook 'nxml-mode-hook 'aw-setup-nxml-mode)
