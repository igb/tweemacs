# Tweemacs

Tweemacs is an Elisp extension for the [Emacs](https://www.gnu.org/software/emacs/) text editor that enables a user to Tweeting the contents of a given buffer.

## Installation Instructions

1. Download and save the file [tweemacs.el](https://raw.githubusercontent.com/igb/tweemacs/master/tweemacs.el) to a local directory on the computer where you run Emacs.

2. Locate your *.emacs* file in your home directory and add the following line:
```Elisp
(load "/path/of/local/directory/where/file/was/saved/into/tweemacs")
```
Note that you do not need the ".el" filename extension in the path, just the path of the local directory in which the downloaded file resides followed by the string "tweemacs".

If you do not have a *.emacs* in your home directory go ahead and create an empty file and add the line described above.

```Shell
touch ~/.emacs; echo  '(load "/path/of/local/directory/where/file/was/saved/into/tweemacs")' >> ~/.emacs
```


### Configuring Twitter Credentials

## How to Tweet

**TL;DR:** *M-x tweet*

### Details ###
1. Open a new buffer or file.
2. Type or enter the Tweet content into the buffer.
3. *M-x tweet* will then, if the buffer length is 140 character or less, send your Tweet.
4. Look for the message *"Tweeted!"* to confirm your Tweet was successfully sent.
5. If an error occurred the error message will be displayed in the Message minibuffer.
