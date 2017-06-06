;;;; Helper functions
(defun refresh-response-is-ok (response)
  (nrepl-dbind-response response (out err reloading status error error-ns after before)
      (equal '("ok") status)))

(defun eval-response-get-return-value (response)
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
       (eval-response-get-return-value)
       (reformat)
       (eval-in-cljs-repl)))

(defun eval-test-run (response log-buffer)
  (when (refresh-response-is-ok response)
    (cider-sync-request:ns-load-all)
    (eval-jsload)
    (cider-test-run-project-tests)))

;;;; Hook

(advice-add 'cider-refresh--handle-response :after #'eval-test-run)
(advice-add 'cider-refresh :before #'save-if-file-buffer)
