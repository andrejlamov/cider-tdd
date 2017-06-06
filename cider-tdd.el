;;;; Helper functions

(defun ctdd-refresh-response-is-ok (response)
  (nrepl-dbind-response response
      (out err reloading status error error-ns after before)
    (equal '("ok") status)))

(defun ctdd-eval-response-get-return-value (response)
  (nrepl-dbind-response response
      (status id ns session value changed-ns repl-type)
    value))

(defun ctdd-remove-surrounding-quotes (e)
  (nth 1 (split-string e "\"")))

(defun ctdd-add-surrounding-parentheses (e)
  (concat "(" e ")"))

(defun ctdd-reformat (e)
  (-> e
      (ctdd-remove-surrounding-quotes)
      (ctdd-add-surrounding-parentheses)))

(defun ctdd-save-if-file-buffer (&optional args)
  (when (buffer-file-name)
    (save-buffer)))

;;;; Core

(defun ctdd-eval-in-cljs-repl (expr)
  (with-current-buffer (cider-current-repl-buffer "cljs")
    (end-of-buffer)
    (insert expr)
    (cider-repl-return)))

(defun ctdd-eval-jsload ()
  (-> "(-> (figwheel-sidecar.system/fetch-config) :data :all-builds first :figwheel :on-jsload)"
       (cider-nrepl-sync-request:eval)
       (ctdd-eval-response-get-return-value)
       (ctdd-reformat)
       (ctdd-eval-in-cljs-repl)))

(defun ctdd-eval-test-run (response log-buffer)
  (when (ctdd-refresh-response-is-ok response)
    (ctdd-eval-jsload)
    (cider-test-run-project-tests)))

;;;; Hook

(advice-add 'cider-refresh--handle-response :after #'ctdd-eval-test-run)
(advice-add 'cider-refresh :before #'ctdd-save-if-file-buffer)
