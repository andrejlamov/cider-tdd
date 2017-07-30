;;;; Helper functions

(defun ctdd-refresh-response-status (response)
  (nrepl-dbind-response response
      (out err reloading status error error-ns after before)
    status))

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

;;;; Refresh hook

(defun ctdd-eval-in-cljs-repl (expr)
  (with-current-buffer (cider-current-repl-buffer "cljs")
    (end-of-buffer)
    (insert expr)
    (cider-repl-return)))

(defun ctdd-eval-jsload ()
  (interactive)
  (-> "(-> (figwheel-sidecar.system/fetch-config) :data :all-builds first :figwheel :on-jsload)"
       (cider-nrepl-sync-request:eval)
       (ctdd-eval-response-get-return-value)
       (ctdd-reformat)
       (ctdd-eval-in-cljs-repl)))

(defun ctdd-eval-test-run (response log-buffer)
  (pcase (ctdd-refresh-response-status response)
    ('("ok") (cider-test-run-project-tests))
    ('("error") (popwin:popup-buffer "*cider-refresh-log*"))
    (other nil)))

(advice-add 'cider-refresh--handle-response :after #'ctdd-eval-test-run)
(advice-add 'cider-refresh :before #'ctdd-save-if-file-buffer)


;;;; Test connection

(setq cider-test-repl "*cider-repl test*")

(defun jack-all-in ()
  (interactive)
  (cider-jack-in)
  (add-hook 'cider-connected-hook 'rename-and-jack-in-rest))

(defun rename-and-jack-in-rest ()
  (cider-change-buffers-designation "test")
  (remove-hook 'cider-connected-hook 'rename-and-jack-in-rest)
  (cider-jack-in-clojurescript))

(defun ctdd-test ()
  (interactive)
  (ctdd-eval-jsload)
  (when cider-test-repl
    (cl-letf ((cider-request-dispatch 'static))
    (noflet ((cider-current-connection (&optional type) (get-buffer cider-test-repl)))
      (cider-refresh)))))

(defun remove-test-connection (connections)
  (cl-remove-if (lambda (b) (equal (buffer-name b) cider-test-repl)) connections))

(advice-add 'cider-find-connection-buffer-for-project-directory :filter-return #'remove-test-connection)
(advice-add 'cider-connections :filter-return #'remove-test-connection)
