(defun eval-in-cljs-repl (expr)
  (with-current-buffer (cider-current-repl-buffer "cljs")
    (insert expr)
    (cider-repl-return)))

(defun eval-jsload ()
  (let* ((get-jsload-expr
          "(-> (figwheel-sidecar.system/fetch-config) :data :all-builds first :figwheel :on-jsload)")
          (response (cider-nrepl-sync-request:eval get-jsload-expr)))
    (nrepl-dbind-response response
        (status id ns session value changed-ns repl-type)
      (let* ((fun-name (nth 1 (split-string value "\"")))
             (expr     (concat "(" fun-name ")")))
        (eval-in-cljs-repl expr)
        ))))

(defun my-cider-refresh-hook (response log-buffer)
  (nrepl-dbind-response response (out err reloading status error error-ns after before)
    (if (equal '("ok") status)
        (progn
          (cider-sync-request:ns-load-all)
          (cider-test-run-project-tests)
          (eval-jsload)
          ))))

(advice-add 'cider-refresh--handle-response :after #'my-cider-refresh-hook)
(advice-add 'cider-refresh :before 'save-buffer)
