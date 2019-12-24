
(size-indication-mode t)

(defun tweet ()
  "Send a tweet!"
  (interactive)
  (if (<= (buffer-size) 140)
      (send-tweet 
       (buffer-substring-no-properties 1 (buffer-size))
       )
    (print "MORE THAN 140 CHARS!"))
   )
  
(defun keep-output (process output)
  (print output))

(defun send-tweet (tweet-body)
  (setq conn (open-network-stream "tweet" nil  "127.0.0.1" 8000))
  (set-process-filter conn 'keep-output)
  (process-send-string conn "GET /library.csv\n\n")

 
  )

;TODO: implement this
(defun escape-uri (x) x)



(defun encode-parameters (parameters)
  (mapcar
   (lambda (parameter)
     	(cons (escape-uri (car parameter)) (escape-uri (cdr  parameter))))  parameters))



(defun create-parameter-string (parameters)
  (setq encoded-parameters  (encode-parameters parameters))
  (setq sorted-encoded-parameters
	(sort encoded-parameters
	      (lambda (a b)
		(string< (car a) (car b)))))

  (mapconcat (lambda (y) (concat (car y) "=" (cdr y)))  sorted-encoded-parameters  "&"))
  
; (defun sign (parameters  url  consumer-secret  oauth-token-secret  http-method)
;  parameter-string = (create-parameter-string parameters)
;  signature-base-string = create-signature-base-string(parameter-string, url, http-method)
;  signing-key= get-signing-key(consumer-secret, oauth-token-secret)
;      base64-encode-to-string(crypto-hmac(sha, signing-key, signature-base-string))




	
