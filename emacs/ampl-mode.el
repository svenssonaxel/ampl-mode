;;; ampl-mode.el --- Major mode for editing Ampl files

;; Filename: ampl-mode.el
;; Copyright (C) 2003, 2008, Dominique Orban, all rights reserved.
;; Homepage: https://github.com/dpo/ampl-mode
;; Version: 0.1
;; Time stamp: "Wed 25 Sep 2013 10:55:10 EDT"

;; The following code is a derivative work of the code written by Dominique Orban,
;; which is licensed GPLv3. This code therefore is also licensed under the terms
;; of the GNU Public License, verison 3.

;; If you find this mode useful, please let me know <dominique.orban@gmail.com>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This file is NOT part of GNU Emacs.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with the Emacs program; see the file COPYING.  If not, write
;; to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Provides syntax highlighting and basic indentation for
;; models written in Ampl.  Ampl is a modeling language for
;; optimization programs.  See www.ampl.com for more information.
;; This file is still under development, features will be added as
;; time allows.  One of these, which I hope to provide in the
;; not-too-distant future is the ability to run an Ampl process in an
;; Emacs window to facilitate model debugging and running.

;;; Code:

;; Hook
(defvar ampl-mode-hook nil
  "*List of functions to call when entering Ampl mode.")

;; Editing
(defvar ampl-mode-map (make-sparse-keymap) "Keymap for Ampl major mode.")
(define-key ampl-mode-map "("     'ampl-insert-pair)
(define-key ampl-mode-map "["     'ampl-insert-pair)
(define-key ampl-mode-map "{"     'ampl-insert-pair)
(define-key ampl-mode-map "\""    'ampl-insert-pair)
(define-key ampl-mode-map "'"     'ampl-insert-pair)
(define-key ampl-mode-map "\C-ao" 'ampl-insert-comment)
(defvar ampl-auto-close t
  "If non-nil, automatically insert closing pairs.
This works for parenthesis, square brackets, curly braces, double quotes and
single quotes.")
(defun ampl-insert-pair ()
  "Insert pair.  See ampl-auto-close."
  (interactive)
  (self-insert-command 1)
  (when ampl-auto-close
    (insert (alist-get (string-to-char (this-command-keys))
                       '(( ?\( . ?\) )
                         ( ?\[ . ?\] )
                         ( ?\{ . ?\} )
                         ( ?\" . ?\" )
                         ( ?\' . ?\' ))))
    (backward-char 1)))

(defvar ampl-user-comment
  "#####
##  %
#####
"
  "# User-defined comment template." )
(defun ampl-insert-comment ()
  "Insert a comment template defined by `ampl-user-comment'."
  (interactive)
  (let ((point-a (point))
	point-b
        point-c)
    (insert ampl-user-comment)
    (setq point-b (point))

    (goto-char point-a)
    (if (re-search-forward "%" point-b t)
	(progn
	  (setq point-c (match-beginning 0))
	  (replace-match ""))
      (goto-char point-b))
    ))

;; Associate file extensions .mod, .dat and .ampl with ampl-mode
(add-to-list 'auto-mode-alist '("\\(.mod\\|.dat\\|.ampl\\)\\'" . ampl-mode))

;; Associate ampl interpreter with ampl-mode
(add-to-list 'interpreter-mode-alist '("ampl" . ampl-mode))

;; Highlighting
(defconst ampl-font-lock
  '(
    ;; Keyword highlighting: model and data statements
    ;; may be followed by a name, must be followed by a semicolon.
    ( "\\(data\\|model\\)\\(.*;\\)" . (1 font-lock-builtin-face keep t))
    ;; Model and data filenames highlighting
    ( "\\(data\\|model\\)\\(.*\\)\\(;\\)" . (2 font-lock-constant-face keep t))
    ;; Other reserved keywords
    ("\\(^\\|[ \t]+\\|[({\[][ \t]*\\)\\(I\\(?:N\\(?:OUT\\)?\\|nfinity\\)\\|LOCAL\\|OUT\\|a\\(?:nd\\|r\\(?:c\\|ity\\)\\)\\|b\\(?:\\(?:inar\\)?y\\)\\|c\\(?:ard\\|heck\\|ircular\\|o\\(?:eff\\|mplements\\|ver\\)\\)\\|d\\(?:ata\\|efault\\|i\\(?:ff\\|men\\|splay\\)\\)\\|e\\(?:lse\\|xists\\)\\|f\\(?:irst\\|orall\\|rom\\)\\|i\\(?:n\\(?:clude\\|dexarity\\|te\\(?:ger\\|r\\(?:val\\)?\\)\\)\\|n\\)\\|l\\(?:ast\\|e\\(?:ss\\|t\\)\\)\\|m\\(?:aximize\\|ember\\|inimize\\)\\|n\\(?:extw?\\|o\\(?:de\\|t\\)\\)\\|o\\(?:bj\\|ption\\|r\\(?:d\\(?:0\\|ered\\)?\\)?\\)\\|p\\(?:aram\\|r\\(?:evw?\\|intf\\)\\)\\|re\\(?:peat\\|versed\\)\\|s\\(?:\\.t\\.\\|et\\(?:of\\)?\\|olve\\|u\\(?:bject to\\|ffix\\)\\|ymbolic\\)\\|t\\(?:able\\|hen\\|o\\)\\|un\\(?:ion\\|til\\)\\|var\\|w\\(?:hile\\|ithin\\)\\)\\({\\|[ \t]+\\|[:;]\\)" . (2 font-lock-builtin-face keep t))
    ;; 'if' is a special case as it may take the forms
    ;; if(i=1), if( i=1 ), if ( i=1 ), if i==1, etc.
    ("\\(^\\|[ \t]+\\|[({\[][ \t]*\\)\\(if\\)\\([ \t]*(\\|[ \t]+\\)" . (2 font-lock-builtin-face keep t))
    ;; 'Infinity' is another special case as it may
    ;; appear as -Infinity...
    ("\\(^\\|[ \t]+\\|[({\[][ \t]*\\)\\(-[ \t]*\\)\\(Infinity\\)\\([ \t]*(\\|[ \t]+\\)" . (3 font-lock-builtin-face keep t))
    ;; Built-in operators highlighting
    ;; must be followed by an opening parenthesis
    ("\\(a\\(?:bs\\|cosh?\\|lias\\|sinh?\\|tan[2h]?\\)\\|c\\(?:eil\\|os\\|time\\)\\|exp\\|floor\\|log\\(?:10\\)?\\|m\\(?:ax\\|in\\)\\|precision\\|round\\|s\\(?:inh?\\|qrt\\)\\|t\\(?:anh?\\|ime\\|runc\\)\\)\\([ \t]*(\\)" . (1 font-lock-function-name-face t t))
    ;; Random number generation functions
    ;; must be followed by an opening parenthesis
    ("\\(Beta\\|Cauchy\\|Exponential\\|Gamma\\|Irand224\\|Normal\\(?:01\\)?\\|Poisson\\|Uniform\\(?:01\\)?\\)\\([ \t]*(\\)" . (1 font-lock-function-name-face t t))
    ;; Built-in operators with iterators
    ;; must be followed by an opening curly brace
    ("\\(prod\\|sum\\)\\([ \t]*{\\)" . (1 font-lock-function-name-face t t))
    ;; Constants, parameters and names
    ;; follow the keywords param, let, set, var, minimize, maximize, option or 'subject to'
    ("\\(^[ \t]*\\)\\(display\\|let\\|m\\(?:\\(?:ax\\|in\\)imize\\)\\|option\\|param\\|s\\(?:\\.t\\.\\|et\\|ubject to\\)\\|var\\)\\([ \t]*\\)\\([a-zA-Z0-9\-_]+\\)\\([ \t]*.*[;:]\\)" . (4 font-lock-constant-face t t))
    ;; Constants may also be defined after a set specification
    ;; This does not involve 'option'
    ;; e.g. let {i in 1..5} x[i] := 0;
    ("\\(^[ \t]*\\)\\(display\\|let\\|m\\(?:\\(?:ax\\|in\\)imize\\)\\|param\\|s\\(?:\\.t\\.\\|et\\|ubject to\\)\\|var\\)\\([ \t]+\\)\\({.*}\\)\\([ \t]*\\)\\([a-zA-Z0-9\-_]+\\)\\([ \t]*.*[;:]\\)" . (6 font-lock-constant-face t t))
    ;; Comments
    ;; Start with a hash, end with a newline
    ( "\\(#\\).*$" . (0 font-lock-comment-face t t))
    ))

;; Indentation --- Fairly simple for now
;;  1) If a line starts with }, decrease the indentation level
;;  2) If a line ends with a colon or an equal sign or {, the next line is indented.
;;  3) Otherwise, keep the same indentation
(defun ampl-indent-line ()
  "Indent current line of Ampl code."
  (interactive)
  (let ((position 0)
        (reason nil)
        (de-indent nil)
        (indent-level 0))

    (save-excursion
      ;; Set point to beginning of line
      (beginning-of-line)

      ;; Flush left at beginning of buffer
      (if (bobp)
          (prog1
              (setq position 0)
            (setq reason "top of buffer"))

        (progn
          ;; Current line begins with "}"?
          (back-to-indentation)
          (setq de-indent (looking-at "}.*$"))

          ;; Find the indentation level of the previous line
          (forward-to-indentation -1) ;; move point to the first non blank char of previous line, if any
          (setq indent-level (/ (current-column) tab-width))

          (cond ((looking-at ".*[:={][ \t]*$")
                 ;; if previous line ends with : or = or {
                 (if de-indent
                     (prog1
                         ;; indent
                         (setq position (* indent-level tab-width))
                       (setq reason "previous line ends in : or = or {, but current line starts with }"))
                   (prog1
                       ;; indent
                       (setq position (* (+ indent-level 1) tab-width))
                     (setq reason "previous line ends in : or = or {"))))
                (de-indent
                 ;; Current line begins with "}"
                 (prog1
                     ;; indent
                     (setq position (max 0 (* (- indent-level 1) tab-width)))
                   (setq reason "current line start with }")))
                (t
                 ;; otherwise, keep current indentation
                 (prog1
                     (setq position (* indent-level tab-width))
                   (setq reason "nothing special")))
                )
          )
        )
      )
    (message "Indentation column will be %d (%s)" position reason)
    (indent-line-to position)))

;; Syntax table for Ampl major mode
(defvar ampl-mode-syntax-table (make-syntax-table)
  "Syntax table for Ampl mode.")
;; Indicate that underscore may be part of a word
(modify-syntax-entry ?_ "w" ampl-mode-syntax-table)
;; Comments start with a hash and end with a newline
(modify-syntax-entry ?# "<" ampl-mode-syntax-table)
(modify-syntax-entry ?\n ">" ampl-mode-syntax-table)

;; Definition of Ampl major mode
(defun ampl-mode ()
  "Major mode for editing Ampl models.
Special commands:
\\{ampl-mode-map}"
  (interactive)
  (kill-all-local-variables)

  ;; Syntax table
  (set-syntax-table ampl-mode-syntax-table)

  ;; Highlighting
  (setq-local
   font-lock-defaults '(ampl-font-lock)
   comment-start "#")

  ;; Indent Ampl commands
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'ampl-indent-line)

  (setq major-mode 'ampl-mode)
  (setq mode-name "Ampl")

  ;; Keymap
  (use-local-map ampl-mode-map)
  (run-mode-hooks 'ampl-mode-hook))

(provide 'ampl-mode)

;;; ampl-mode.el ends here
