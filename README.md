rssReader
=========

A RSS feed reader split into a simple server (as a starkit) and a browser GUI

This is really a quick application of my own web server **Tatu**, written in tcl, with a plugin (all enclosed in the .kit file) to fetch data from RSS/Atom feeds configured by the user. The application is delivered as a single starkit, rssReader.kit, and requires only *tclkit* (for Linux, or *tclkit.exe* under Windows) to execute. You may get your tclkit executable from https://code.google.com/p/tclkit/

You must place a file named *subscriptions.xml* with the feeds list, 
as retrieved from Google Reader. It is an OPML standard file, as you may find
in our sample.
Then, run rssReader with the following command:

> `tclkit rssReader.kit`

or also (with a GUI to access the tkcon console):

> `tclkit rssReader.kit gui`

After that, you should run your favorite browser (I tested with Firefox and Google Chrome and both works flawlessly), and point it to http://localhost:15732/
After the program starts in the browser, you have to choose a subject to fetch 
all news about that subject.

You may find interesting to visit my personal homepage at http://pragana.net or send me an email asking for features or suggesting me some improvements. You are welcome.

