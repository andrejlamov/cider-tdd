;;;; Helper functions

(defun match-out-return-value (response)
  (nrepl-dbind-response response
      (status id ns session value changed-ns repl-type)
    value))

(defun remove-surrounding-quotes (e)
  (nth 1 (split-string e "\"")))

(defun add-surrounding-parentheses (e)
  (concat "(" e ")"))

(defun reformat (e)
  (-> e
      (remove-surrounding-quotes)
      (add-surrounding-parentheses)))

(defun save-if-file-buffer (&optional args)
  (when (not (buffer-file-name))
    (save-buffer)))

;;;; Core

(defun eval-in-cljs-repl (expr)
  (with-current-buffer (cider-current-repl-buffer "cljs")
    (end-of-buffer)
    (insert expr)
    (cider-repl-return)))

(defun eval-jsload ()
  (-> "(-> (figwheel-sidecar.system/fetch-config) :data :all-builds first :figwheel :on-jsload)"
       (cider-nrepl-sync-request:eval)
       (match-out-return-value)
       (reformat)
       (eval-in-cljs-repl)))

(defun my-cider-refresh-hook (response log-buffer)
  (nrepl-dbind-response response (out err reloading status error error-ns after before)
    (if (equal '("ok") status)
        (progn
          (cider-sync-request:ns-load-all)
          (cider-test-run-project-tests)
          (eval-jsload)))))

;;;; Hook

(advice-add 'cider-refresh--handle-response :after #'my-cider-refresh-hook)
(advice-add 'cider-refresh :before 'save-buffer)
(advice-add 'cider-refresh :before #'save-if-file-buffer)
