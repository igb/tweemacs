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
The Tweemacs extension is going to need credentials in order to post Tweets as you on Twitter. To get these credentials, you will need to create an app and then generate credentials that Tweemacs will use to authN and authZ with Twitter when sending Tweets.

To get started, create a developer account at [https://developer.twitter.com](https://developer.twitter.com).

Once your Twitter developer account has been created, log in to the developer site and go into *Apps*. Then click on the *Create App* button.

After you have created your app got to the *Keys and Tokens* section in the app detail page. Click the *Generate* button and you will see a *Consumer API keys* and *Access token & access token secret* sections, each with two values (keys/tokens and coressponding secrets).

On your local machine, create a *.tweemacs* file in your home directory (*~/*) and enter the information generated above in the follwing format/order:


```Text
API_KEY=eG4hy64h2fqhx9ba4OsJl3Pqf
API_SECRET=vrGZ3026iVNIZKj5ip9onv7VvLVG6yC3zG3ErwFHYiCjqmVISq
ACCESS_TOKEN=3214574609876654321-26iVNIZVG6yC3zG3ErwFBIJXoo
ACCESS_TOKEN_SECRET=Qb24h2fqhx9ba2mb9IXZKj5ip9onv7VZpWQorJQOBIJX
```

Your values will differ, obviously, but make sure the property names are the same.

Ok, now you are good to go. Just launch or restart Emacs!

## How to Tweet

**TL;DR:** *M-x tweet*

### Details ###
1. Open a new buffer or file.
2. Type or enter the Tweet content into the buffer.
3. *M-x tweet* will then, if the buffer length is 140 character or less, send your Tweet.
4. Look for the message *"Tweeted!"* to confirm your Tweet was successfully sent.
5. If an error occurred the error message will be displayed in the Message minibuffer.

## Questions? ##

You can always contact me with any questions at [@igb](https://twitter.com/igb).
