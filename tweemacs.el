
(size-indication-mode t)


(defun read-creds ()
    "Read auth tokens from local file"
    (with-temp-buffer
      (insert-file-contents "~/.tweemacs")
      (setq raw-creds (split-string (buffer-string) "\n" t))
      (setq cred-nvps (mapcar (lambda (x) (split-string x "=")) raw-creds))
      (mapcar (lambda (x) (set (intern (car x)) (car (cdr x)))) cred-nvps)))

(defun tweet ()
  "Send a tweet!"
  (interactive)

  (if (<= (buffer-size) 280)
      (send-tweet 
       (buffer-substring-no-properties (point-min) (point-max))
       )
    (print "MORE THAN 280 CHARS!"))
   )
  
(defun keep-output (process output)
  "Manage and process output anc check status of Tweet action."
  (sleep-for 3) ;; async is hard 
  (setq lines (split-string output "\r\n" t))
  (if (string-prefix-p "HTTP/1.1 200 OK" (car lines))
      (message "Tweeted!")
    (handle-error lines))
   
  (delete-process conn))


(defun handle-error (lines)
  "Handle error or non-200 condition!"
  (mapcar (lambda (x)
	    
	    (if (string-prefix-p "{\"errors\":" x)
		(message (concat "ERROR: " (car (cdr (reverse (split-string x  "[\"]"))))))
	      )
	    )
	  lines)
   )


(defun oauth-timestamp ()
  "Returns an OAuth timestamp string: seconds from the epoch"
  (number-to-string (floor (time-to-seconds))))

(defun oauth-nonce ()
  "Returns an OAuth nonce string"
  (base64-encode-string (number-to-string  (time-to-seconds))))


(defun send-tweet (tweet-body)
  
  (read-creds)
  
  (setq escaped-tweet (escape-uri tweet-body))
  (setq status (concat "status=" escaped-tweet))

 

  (setq headers (concat "Accept: */*\r\n"
			"Host: api.twitter.com\r\n" 
			"Content-Type: application/x-www-form-urlencoded\r\n"
			"Authorization: "
			(create-oauth-header `(("status" . ,tweet-body)) "https://api.twitter.com/1.1/statuses/update.json"  API_KEY API_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET (oauth-nonce) (oauth-timestamp) "post") "\r\n" "Content-Length: " (number-to-string (length status))))
	      
  
  (setq conn (open-network-stream "tweet" nil  "api.twitter.com" 443  :type 'tls))
  (set-process-filter conn 'keep-output)
  (setq body (concat "POST /1.1/statuses/update.json HTTP/1.1\r\n" headers "\r\n\r\n" status))
 
  (process-send-string conn body)

	)


(defun escape-uri (x)
  (url-hexify-string x))



(defun encode-parameters (parameters)
  (mapcar
   (lambda (parameter)
     (cons
      (escape-uri (car parameter))
      (escape-uri (cdr parameter))
      )
     )  parameters))


(defun sort-parameters (parameters)
  "Sort an alist by the first element in each alist."
  (sort encoded-parameters
	      (lambda (a b)
		(string< (car a) (car b)))))
  
(defun create-parameter-string (parameters)
  (setq encoded-parameters  (encode-parameters parameters))
  (setq sorted-encoded-parameters
	(sort-parameters encoded-parameters))

  (mapconcat
   (lambda (y)
     (concat (car y) "=" (cdr y))
     ) sorted-encoded-parameters  "&"))




(defun create-signature-base-string (parameter-string  url http-method)
  (concat (upcase http-method)  "&" (escape-uri url) "&" (escape-uri parameter-string)))

(defun get-signing-key(consumer-secret oauth-token-secret)
  (concat (escape-uri consumer-secret) "&"  (escape-uri oauth-token-secret)))

(defun zipxor (a b acc)
  "Apply `logxor' to each element of list a and list b `(logxor a b) returning a list of the xor'd values."
  (if (= (length a) 0)
      acc
    (setq new-acc (append acc (cons (logxor (car a) (car b)) '())))
    (zipxor (cdr a) (cdr b) new-acc)))


(defun bytepad(origin width padbyte)
  "Pad the origin string to the width parameter using the supplied padbyte. 
For example `(bytepad \"foo\" 10 #x42)' would return the string `\"fooBBBBBBB\"'"
  (while (< (length origin) width)
    (setq origin (concat origin (byte-to-string padbyte))))
  origin)



(defun coerce (putative-binary)
  "These should be unecessary and seems like a no-op, but fuck Elisp."
  (base64-decode-string (base64-encode-string putative-binary)))


(defun hmac-sha1 (key message &optional binary)
  "Generate a HMAC-SHA1 message authentication code for a given `key' and `message'. By default, it returns a hexadecimal-encoded string of the MAC. If the optional `binary' paramater is not `nil' then the function will return the raw binary-encoded bytes."
  (setq block-size 64) 
  (setq output-size 20)

  
  (if (> (length key) block-size)
      (setq key (concat "" (secure-hash 'sha1 key nil nil "t"))))
  
  (if (< (length key) block-size)
      (setq key (bytepad key block-size #x00)))

  
  
  (setq o-key-pad  (zipxor (string-to-list key) (string-to-list (bytepad "" block-size #x5c)) '()))
  
  (setq i-key-pad (zipxor (string-to-list key) (string-to-list (bytepad "" block-size #x36)) '()))

  
  (secure-hash 'sha1
	       (coerce (concat "" o-key-pad
			       (secure-hash 'sha1
					    (coerce (concat "" i-key-pad  message)) nil nil "t"))) nil nil binary))

(defun sign (parameters url consumer-secret oauth-token-secret http-method)
  (setq parameter-string  (create-parameter-string parameters))
  (setq signature-base-string (create-signature-base-string parameter-string  url  http-method))
  (setq signing-key (get-signing-key consumer-secret  oauth-token-secret))
  (base64-encode-string (hmac-sha1 signing-key signature-base-string 't)))


(defun create-oauth-header-string (parameters)
  "Encode and concatenate the OAuth parameters into the OAuth headers string"
  (setq encoded-parameters (encode-parameters parameters))
  (setq sorted-encoded-parameters (sort-parameters encoded-parameters))
  (concat "OAuth " (mapconcat
   (lambda (y)
     (concat (car y) "=\"" (cdr y) "\"")
     ) sorted-encoded-parameters  ", ")))


(defun create-oauth-header (request-parameters url consumer-key  consumer-secret oauth-token oauth-token-secret oauth-nonce oauth-timestamp http-method)

       (setq oauth-signature-method "HMAC-SHA1")
       (setq oauth-version "1.0")


       (setq oauth-parameters `(("oauth_consumer_key" . ,consumer-key)
			    ("oauth_nonce" . ,oauth-nonce)
			    ("oauth_signature_method" . ,oauth-signature-method)
			    ("oauth_timestamp" . ,oauth-timestamp)
			    ("oauth_token" . ,oauth-token)
			    ("oauth_version" . ,oauth-version)))
       
       (setq signing-parameters (append oauth-parameters request-parameters))
       (setq oauth-signature (sign signing-parameters url consumer-secret oauth-token-secret http-method))
       (setq signed-oauth-parameters (append oauth-parameters `(("oauth_signature" .  ,oauth-signature))))
       (create-oauth-header-string signed-oauth-parameters))
       

;; UNIT TESTS
(require 'ert)

(defun get-test-parameters ()
  '(("include_entities" .  "true")
  ("status" . "Hello Ladies + Gentlemen, a signed OAuth request!")
  ("oauth_consumer_key" ."xvz1evFS4wEEPTGEFPHBog")
  ("oauth_nonce". "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg")
  ("oauth_signature_method" . "HMAC-SHA1")
  ("oauth_timestamp" . "1318622958")
  ("oauth_token" . "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb")
  ("oauth_version" . "1.0")))

(ert-deftest tweemacs-test-escape-uri ()
  "Tests the conversion of a string to a URL encoded string."
  (should
   (equal
    (escape-uri "Hello Ladies + Gentlemen, a signed OAuth request!")
    "Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21")))
	
(ert-deftest tweemacs-test-create-parameter-string ()
  "Tests the creation of a paramter string from an alist of parameters"
  (should
   (equal
    (create-parameter-string (get-test-parameters))
    "include_entities=true&oauth_consumer_key=xvz1evFS4wEEPTGEFPHBog&oauth_nonce=kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1318622958&oauth_token=370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb&oauth_version=1.0&status=Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21")))


(ert-deftest tweemacs-test-create-signature-base ()
  "Tests the composition of the signature base string for OAuth."
  (should
   (equal
    (create-signature-base-string (create-parameter-string (get-test-parameters)) "https://api.twitter.com/1/statuses/update.json" "post")
    "POST&https%3A%2F%2Fapi.twitter.com%2F1%2Fstatuses%2Fupdate.json&include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521")))


(ert-deftest tweemacs-test-get-signing-key ()
  "Tests the concatenation and creation of the signing key from it's constotuent parts."
  (should
   (equal
    (get-signing-key "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw" "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE")
    "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw&LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE")))

(ert-deftest tweemacs-test-hmac-sha1-zero-length-message ()
  "Tests the bespoke HMAC-SHA1 inadvisably implemented in this extension,"
  (should
   (equal
    (hmac-sha1 "key" "")
    "f42bb0eeb018ebbd4597ae7213711ec60760843f" ))) 


(ert-deftest tweemacs-test-hmac-sha1-simple-key-message-001()
  "Tests the bespoke HMAC-SHA1 inadvisably implemented in this extension,"
  (should
   (equal
    (hmac-sha1 "bar" "foo")
    "85d155c55ed286a300bd1cf124de08d87e914f3a" )))

(ert-deftest tweemacs-test-hmac-sha1-simple-key-message-002 ()
  "Tests the bespoke HMAC-SHA1 inadvisably implemented in this extension,"
  (should
   (equal
    (hmac-sha1 "key" "The quick brown fox jumps over the lazy dog")
    "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9" )))

(ert-deftest tweemacs-test-hmac-sha1-message-larger-than-block-size ()
  "Tests the bespoke HMAC-SHA1 inadvisably implemented in this extension,"
  (should
   (equal
    (hmac-sha1 "key" "In cryptography, an HMAC (sometimes expanded as either keyed-hash message authentication code or hash-based message authentication code) is a specific type of message authentication code (MAC) involving a cryptographic hash function and a secret cryptographic key. It may be used to simultaneously verify both the data integrity and the authenticity of a message, as with any MAC. Any cryptographic hash function, such as SHA-256 or SHA-3, may be used in the calculation of an HMAC; the resulting MAC algorithm is termed HMAC-X, where X is the hash function used (e.g. HMAC-SHA256 or HMAC-SHA3). The cryptographic strength of the HMAC depends upon the cryptographic strength of the underlying hash function, the size of its hash output, and the size and quality of the key.")
    "ae46438aada90b8d2b35ad2a7344925805457621" )))


(ert-deftest tweemacs-test-hmac-sha1-key-larger-than-block-size ()
  "Tests the bespoke HMAC-SHA1 inadvisably implemented in this extension,"
  (should
   (equal
    (hmac-sha1 "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33MGJlZWM3YjVlYTNmMGZkYmM5NWQwZGQ0N2YzYzViYzI3NWRhOGEzMw==" "The quick brown fox jumps over the lazy dog")
    "e4db689e83caef6c1d3520aa4a1eaf4b83e54f89" )))


(ert-deftest tweemacs-test-sign ()
  "Tests a full sign of request components."
  (should
   (equal
    (sign (get-test-parameters) "https://api.twitter.com/1/statuses/update.json"  "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw" "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE" "post")
    "tnnArxj06cWHq44gCs1OSKk/jLY=")))


(ert-deftest tweemacs-test-create-oauth-header-string()
  "Tests the construction of the OAuth HTTP Header value string syntax."
  (should
   (equal
    (create-oauth-header-string '(("foo" . "bar") ("bing" . "bat")))
    "OAuth bing=\"bat\", foo=\"bar\"")))

(ert-deftest tweemacs-test-create-oauth-header ()
  "Tests the construction and signing of the OAuth HTTP Header value."
  (setq request-parameters '(("include_entities" . "true")
			     ("status" . "Hello Ladies + Gentlemen, a signed OAuth request!")))
  (setq url  "https://api.twitter.com/1/statuses/update.json")
  (setq consumer-key  "xvz1evFS4wEEPTGEFPHBog")
  (setq consumer-secret "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw")
  (setq oauth-token "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb")
  (setq oauth-token-secret "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE")
  (setq oauth-nonce "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg")
  (setq oauth-timestamp  "1318622958")
  (setq http-method "Post")
  (setq oauth-header  (create-oauth-header request-parameters url consumer-key consumer-secret oauth-token oauth-token-secret oauth-nonce oauth-timestamp http-method))
  (should
   (equal
    oauth-header "OAuth oauth_consumer_key=\"xvz1evFS4wEEPTGEFPHBog\", oauth_nonce=\"kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg\", oauth_signature=\"tnnArxj06cWHq44gCs1OSKk%2FjLY%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1318622958\", oauth_token=\"370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb\", oauth_version=\"1.0\"")))
      


  
