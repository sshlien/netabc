Netabc.tcl is a user interface for creating web pages that display the
contents of abc music notation files using Jef Moine's
[Abc2svg](https://chiselapp.com/user/moinejf/repository/abc2svg/doc/trunk/README.md)
JavaScript library. Every browser whether it is on a desktop, cellphone or
tablet has a JavaScript engine that can render this music. Since the music
notation displays and plays on your browser, you no longer need external
applications such as a PostScript or Pdf viewer or even a midi player.

The program is a tcl/tk script so it requires tcl/tk 8.5 or 8.6 to be
installed on your system. Windows users can avoid installing tcl/tk on
Windows, by running the netabc.exe executable which contains the tcl/tk
interpreter. Otherwise you can get tcl/tk for free from
[www.activestate.com](https://www.activestate.com/products/tcl/downloads/).

Using netabc, you open an abc music notation file, select one of the tunes,
and render it in common music notation in your browser and play the contents.
Netabc.tcl creates an html file containing this tune and links it to the
JavaScript library. The temporary html file is then loaded into your browser.
The browser executes the JavaScript and replaces the abc notation by scaleable
vector graphics (svg). This graphics displays the tune in common music
notation. If you click on one of the displayed notes, the browser will play
the music and follow along. The generated html file is stored on your
computer, allowing you to view or edit it.

Though it is possible to create such web pages with just an ordinary text
editor, this is not a trivial task. Netabc provides several different methods
for embedding the abc file. It allows you to experiment with the different
formatting options. Different MIDI musical instruments can be assigned to the
various voices.

A more detailed description of the program can be found on
[netabc.sourceforge.io](https://netabc.sourceforge.io/).

