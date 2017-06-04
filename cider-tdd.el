(defun my-cider-refresh-hook (response log-buffer)
  (nrepl-dbind-response response (out err reloading status error error-ns after before)
    (if (equal '("ok") status)
        (progn
          (cider-sync-request:ns-load-all)
          (cider-test-run-project-tests)
          ))))

(advice-add 'cider-refresh--handle-response :after #'my-cider-refresh-hook)
(advice-add 'cider-refresh :before 'save-buffer)
