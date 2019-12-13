
(size-indication-mode t)

(defun tweet ()
  "Send a tweet."
  (interactive)
  (if (<= (buffer-size) 140)
      (print 
       (buffer-substring-no-properties 1 (buffer-size)))
    (print "MORE THAN 140 CHARS!"))
   )
  

(defun send-tweet (tweet-body)) 