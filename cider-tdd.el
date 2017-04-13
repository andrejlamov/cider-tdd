(setq nr-of-loaded-files  0)
(setq nr-of-files-to-load 0)

(defun reset-counters ()
  (setq nr-of-loaded-files  0)
  (setq nr-of-files-to-load 0))

(defun all-files-are-loaded ()
  (and (eq nr-of-files-to-load
           nr-of-loaded-files)
       (not (eq 0 nr-of-files-to-load))))

(defun maybe-run-tests ()
  (incf nr-of-loaded-files)
  (when (all-files-are-loaded)
    (cider-test-run-project-tests)))

(defun construct-find-command (src-folder test-folder)
  (format "find %s %s -name \"*.clj\" -or -name \"*.cljc\""
          (concat (projectile-project-root) src-folder)
          (concat (projectile-project-root) test-folder)))

(defun list-all-files-in-project (src-folder test-folder)
    (->>
     (construct-find-command src-folder test-folder)
     (shell-command-to-string)
     (string-trim)
     ((lambda (output) (split-string output "\n")))
     (mapcar 'file-truename)))

(defun evaluate-files (paths)
  (dolist (p paths) (cider-eval-file p)))

(defun my-cider-load-and-test-project ()
  (interactive)
  (my-cider-load-and-test-files
   (list-all-files-in-project "src" "test")))

(defun my-cider-load-and-test-current ()
  (interactive)
  (my-cider-load-and-test-files (list (buffer-file-name))))

(defun my-cider-load-and-test-files (paths)
  (reset-counters)
  (setq nr-of-files-to-load (length paths))
  (evaluate-files paths)
  (message "Loading and testing all files in project..."))

(defun test-on-save ()
  (interactive)
  (when (member major-mode '(clojurec-mode clojure-mode))
    (my-cider-load-and-test-project)))

(add-hook 'cider-file-loaded-hook 'maybe-run-tests)
(add-hook 'after-save-hook 'test-on-save)
(push '("*cider-test-report*" :width 0.6 :position right) popwin:special-display-config)
