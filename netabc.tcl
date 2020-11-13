#
#package provide app-netabc 1.0
#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

# netabc.tcl
#
## Copyright (C) 1998-2020 Seymour Shlien
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

set netabc_version 0.187
set netabc_date "(October 13 2020 10:00)"
set app_title "netabc $netabc_version $netabc_date"
set tcl_version [info tclversion]

package require Tk
if {[catch {package require Ttk} error]} {
    puts $error
    puts "I am looking for this package in $auto_path"
    puts "Be sure you are running Tcl/Tk 8.5 or higher"
}

# procedures:
#   write_netabc_ini
#   read_netabc_ini
#   netstate_ini
# main interface
#   show_config
#   open_editor
#   show_titles
#   show_message_page
#   file_browser
#   setpath
#   setpathjslib
#   update_url_pointer
#   open_abc_file
#   load_whole_file
#   update_history
#   process_history
#   delete_history
#   title_index
#   SortBy
#   title_selected
#   abc_header_to_array
#   write_netheader_ini
#   read_netheader_ini
#   close_header
#   create_header_frame
#   reset_abc_header
#   make_abc_header_from_array
#   update_preface
#   find_X_code
#   get_nonblank_line
#   copy_selected_tunes_to_html
#   export_to_browser
#   open_help_in_browser
#   voice_button
#   program_popup
#   program_select
#   reset_midi_voice




# tooltip.tcl --
#
#       Balloon help
#
# Copyright (c) 1996-2003 Jeffrey Hobbs
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# RCS: @(#) $Id: tooltip.tcl,v 1.5 2005/11/22 00:55:07 hobbs Exp $
#
# Initiated: 28 October 1996


package require Tk 8.5
package provide tooltip 1.1


#------------------------------------------------------------------------
# PROCEDURE
#	tooltip::tooltip
#
# DESCRIPTION
#	Implements a tooltip (balloon help) system
#
# ARGUMENTS
#	tooltip <option> ?arg?
#
# clear ?pattern?
#	Stops the specified widgets (defaults to all) from showing tooltips
#
# delay ?millisecs?
#	Query or set the delay.  The delay is in milliseconds and must
#	be at least 50.  Returns the delay.
#
# disable OR off
#	Disables all tooltips.
#
# enable OR on
#	Enables tooltips for defined widgets.
#
# <widget> ?-index index? ?-item id? ?message?
#	If -index is specified, then <widget> is assumed to be a menu
#	and the index represents what index into the menu (either the
#	numerical index or the label) to associate the tooltip message with.
#	Tooltips do not appear for disabled menu items.
#	If message is {}, then the tooltip for that widget is removed.
#	The widget must exist prior to calling tooltip.  The current
#	tooltip message for <widget> is returned, if any.
#
# RETURNS: varies (see methods above)
#
# NAMESPACE & STATE
#	The namespace tooltip is used.
#	Control toplevel name via ::tooltip::wname.
#
# EXAMPLE USAGE:
#	tooltip .button "A Button"
#	tooltip .menu -index "Load" "Loads a file"
#
#------------------------------------------------------------------------

namespace eval ::tooltip {
    namespace export -clear tooltip
    variable tooltip
    variable G
    
    array set G {
        enabled		1
        DELAY		500
        AFTERID		{}
        LAST		-1
        TOPLEVEL	.__tooltip__
    }
    
    # The extra ::hide call in <Enter> is necessary to catch moving to
    # child widgets where the <Leave> event won't be generated
    bind Tooltip <Enter> [namespace code {
        #tooltip::hide
        variable tooltip
        variable G
        set G(LAST) -1
        if {$G(enabled) && [info exists tooltip(%W)]} {
            set G(AFTERID) \
                    [after $G(DELAY) [namespace code [list show %W $tooltip(%W) cursor]]]
        }
    }]
    
    bind Menu <<MenuSelect>>	[namespace code { menuMotion %W }]
    bind Tooltip <Leave>	[namespace code hide]
    bind Tooltip <Any-KeyPress>	[namespace code hide]
    bind Tooltip <Any-Button>	[namespace code hide]
}

proc ::tooltip::tooltip {w args} {
    variable tooltip
    variable G
    switch -- $w {
        clear	{
            if {[llength $args]==0} { set args .* }
            clear $args
        }
        delay	{
            if {[llength $args]} {
                if {![string is integer -strict $args] || $args<50} {
                    return -code error "tooltip delay must be an\
                            integer greater than 50 (delay is in millisecs)"
                }
                return [set G(DELAY) $args]
            } else {
                return $G(DELAY)
            }
        }
        off - disable	{
            set G(enabled) 0
            hide
        }
        on - enable	{
            set G(enabled) 1
        }
        default {
            set i $w
            if {[llength $args]} {
                set i [uplevel 1 [namespace code "register [list $w] $args"]]
            }
            set b $G(TOPLEVEL)
            if {![winfo exists $b]} {
                toplevel $b -class Tooltip
                if {[tk windowingsystem] eq "aqua"} {
                    ::tk::unsupported::MacWindowStyle style $b help none
                } else {
                    wm overrideredirect $b 1
                }
                wm positionfrom $b program
                wm withdraw $b
                label $b.label -highlightthickness 0 -relief solid -bd 1 \
                        -background lightyellow -fg black
                pack $b.label -ipadx 1
            }
            if {[info exists tooltip($i)]} { return $tooltip($i) }
        }
    }
}

proc ::tooltip::register {w args} {
    variable tooltip
    set key [lindex $args 0]
    while {[string match -* $key]} {
        switch -- $key {
            -index	{
                if {[catch {$w entrycget 1 -label}]} {
                    return -code error "widget \"$w\" does not seem to be a\
                            menu, which is required for the -index switch"
                }
                set index [lindex $args 1]
                set args [lreplace $args 0 1]
            }
            -item	{
                set namedItem [lindex $args 1]
                if {[catch {$w find withtag $namedItem} item]} {
                    return -code error "widget \"$w\" is not a canvas, or item\
                            \"$namedItem\" does not exist in the canvas"
                }
                if {[llength $item] > 1} {
                    return -code error "item \"$namedItem\" specifies more\
                            than one item on the canvas"
                }
                set args [lreplace $args 0 1]
            }
            default	{
                return -code error "unknown option \"$key\":\
                        should be -index or -item"
            }
        }
        set key [lindex $args 0]
    }
    if {[llength $args] != 1} {
        return -code error "wrong \# args: should be \"tooltip widget\
                ?-index index? ?-item item? message\""
    }
    if {$key eq ""} {
        clear $w
    } else {
        if {![winfo exists $w]} {
            return -code error "bad window path name \"$w\""
        }
        if {[info exists index]} {
            set tooltip($w,$index) $key
            #bindtags $w [linsert [bindtags $w] end "TooltipMenu"]
            return $w,$index
        } elseif {[info exists item]} {
            set tooltip($w,$item) $key
            #bindtags $w [linsert [bindtags $w] end "TooltipCanvas"]
            enableCanvas $w $item
            return $w,$item
        } else {
            set tooltip($w) $key
            bindtags $w [linsert [bindtags $w] end "Tooltip"]
            return $w
        }
    }
}

proc ::tooltip::clear {{pattern .*}} {
    variable tooltip
    foreach w [array names tooltip $pattern] {
        unset tooltip($w)
        if {[winfo exists $w]} {
            set tags [bindtags $w]
            if {[set i [lsearch -exact $tags "Tooltip"]] != -1} {
                bindtags $w [lreplace $tags $i $i]
            }
            ## We don't remove TooltipMenu because there
            ## might be other indices that use it
        }
    }
}

proc ::tooltip::show {w msg {i {}}} {
    # Use string match to allow that the help will be shown when
    # the pointer is in any child of the desired widget
    if {![winfo exists $w] || ![string match $w* [eval [list winfo containing] [winfo pointerxy $w]]]} {
        return
    }
    
    variable G
    
    set b $G(TOPLEVEL)
    $b.label configure -text $msg
    update idletasks
    if {$i eq "cursor"} {
        set y [expr {[winfo pointery $w]+20}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            set y [expr {[winfo pointery $w]-[winfo reqheight $b]-5}]
        }
    } elseif {$i ne ""} {
        set y [expr {[winfo rooty $w]+[winfo vrooty $w]+[$w yposition $i]+25}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            # show above if we would be offscreen
            set y [expr {[winfo rooty $w]+[$w yposition $i]-\
                        [winfo reqheight $b]-5}]
        }
    } else {
        set y [expr {[winfo rooty $w]+[winfo vrooty $w]+[winfo height $w]+5}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            # show above if we would be offscreen
            set y [expr {[winfo rooty $w]-[winfo reqheight $b]-5}]
        }
    }
    if {$i eq "cursor"} {
        set x [winfo pointerx $w]
    } else {
        set x [expr {[winfo rootx $w]+[winfo vrootx $w]+\
                    ([winfo width $w]-[winfo reqwidth $b])/2}]
    }
    # only readjust when we would appear right on the screen edge
    if {$x<0 && ($x+[winfo reqwidth $b])>0} {
        set x 0
    } elseif {($x+[winfo reqwidth $b])>[winfo screenwidth $w]} {
        set x [expr {[winfo screenwidth $w]-[winfo reqwidth $b]}]
    }
    if {[tk windowingsystem] eq "aqua"} {
        set focus [focus]
    }
    wm geometry $b +$x+$y
    wm deiconify $b
    raise $b
    if {[tk windowingsystem] eq "aqua" && $focus ne ""} {
        # Aqua's help window steals focus on display
        after idle [list focus -force $focus]
    }
}

proc ::tooltip::menuMotion {w} {
    variable G
    
    if {$G(enabled)} {
        variable tooltip
        
        set cur [$w index active]
        # The next two lines (all uses of LAST) are necessary until the
        # <<MenuSelect>> event is properly coded for Unix/(Windows)?
        if {$cur == $G(LAST)} return
        set G(LAST) $cur
        # a little inlining - this is :hide
        after cancel $G(AFTERID)
        catch {wm withdraw $G(TOPLEVEL)}
        if {[info exists tooltip($w,$cur)] || \
                    (![catch {$w entrycget $cur -label} cur] && \
                    [info exists tooltip($w,$cur)])} {
            set G(AFTERID) [after $G(DELAY) \
                    [namespace code [list show $w $tooltip($w,$cur) $cur]]]
        }
    }
}

proc ::tooltip::hide {args} {
    variable G
    
    after cancel $G(AFTERID)
    catch {wm withdraw $G(TOPLEVEL)}
}

proc ::tooltip::wname {{w {}}} {
    variable G
    if {[llength [info level 0]] > 1} {
        # $w specified
        if {$w ne $G(TOPLEVEL)} {
            hide
            destroy $G(TOPLEVEL)
            set G(TOPLEVEL) $w
        }
    }
    return $G(TOPLEVEL)
}

proc ::tooltip::itemTip {w args} {
    variable tooltip
    variable G
    
    set G(LAST) -1
    set item [$w find withtag current]
    if {$G(enabled) && [info exists tooltip($w,$item)]} {
        set G(AFTERID) [after $G(DELAY) \
                [namespace code [list show $w $tooltip($w,$item) cursor]]]
    }
}

proc ::tooltip::enableCanvas {w args} {
    $w bind all <Enter> [namespace code [list itemTip $w]]
    $w bind all <Leave>		[namespace code hide]
    $w bind all <Any-KeyPress>	[namespace code hide]
    $w bind all <Any-Button>	[namespace code hide]
}

# end of tooltip.tcl




set netabc_path "."
wm title . $app_title

wm protocol . WM_DELETE_WINDOW {
    #confirm_save
    write_netabc_ini $netabc_path
    write_netheader_ini
    exit
    }


# save all options, current abc file
proc write_netabc_ini {netabc_path} {
    global netstate
    set outfile [file join $netabc_path netabc.ini]
    set handle [open $outfile w]
    #tk_messageBox -message "writing $outfile"  -type ok
    foreach item [lsort [array names netstate]] {
        puts $handle "$item $netstate($item)"
    }
    close $handle
}

global netstate

proc read_netabc_ini {netabc_path} {
    global netstate df tocf
    set infile [file join $netabc_path netabc.ini]
    if {![file exist $infile]} return
    set handle [open $infile r]
    while {[gets $handle line] >= 0} {
        set error_return [catch {set n [llength $line]} error_out]
        if {$error_return} continue
        set contents ""
        set param [lindex $line 0]
        for {set i 1} {$i < $n} {incr i} {
            set contents [concat $contents [lindex $line $i]]
        }
        #if param is not already a member of the netstate array
	#(set by netstate_init), #then we ignore it. This prevents
	#netstate array filling up with obsolete parameters used
	#in older versions of the program.
        set member [array names netstate $param]
        if [llength $member] { set netstate($param) $contents }
    }
    font configure $df -family $netstate(font_family) -size $netstate(font_size) \
            -weight $netstate(font_weight)
}


# set default state of netstate in case you are running
# netabc.tcl for the first time.
proc netstate_init {} {
    global netstate df sf 
    global netabc_version
    global tcl_platform
    global netabc_path
    set netstate(version) $netabc_version
    set netstate(font_family) [font actual helvetica -family]
    set netstate(font_family_toc) courier
    set netstate(font_size) 10
    set netstate(encoder) [encoding system]
    if {$netstate(font_size) <10} {set netstate(font_size) 10}
    set netstate(font_weight) bold
    set df [font create -family $netstate(font_family) -size $netstate(font_size) \
            -weight $netstate(font_weight)]
    set netstate(blank_lines) 1
    set netstate(eol) 1
    set netstate(index_by_position) 0
    if {$tcl_platform(platform) == "windows"} {
        set netstate(browser) "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
        if {![file exist $netstate(browser)]} {
          set netstate(browser) "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
          }
        set netstate(editor) "C:/Windows/System32/notepad.exe"
    } else {
        set netstate(browser) firefox
        set netstate(editor) "vim"
    }
    set netstate(remote) 1
    set netstate(outhtml) [file join [pwd] tune.html]
    set netstate(jslib) ".\js"
    set netstate(mididata) 0
    set netstate(abc_open) ""
    set netstate(webscript) 2
    set netstate(abcenclose) 4

    set netstate(history_length) 0
    for {set i 0} {$i < 10} {incr i} {set netstate(history$i) ""}

    for {set i 0} {$i <= 16} {incr i} {
        set netstate(lvoice$i) 64
        set netstate(voice$i) 0
        set netstate(pvoice$i) 64
    }

 }

netstate_init
read_netabc_ini $netabc_path


########### main interface #############
#
#
frame .abc
frame .abc.file
frame .abc.functions -borderwidth 3
frame .abc.titles

# file entry and button
#if {[info exists abc_open]} {set netstate(abc_open) $abc_open}
entry .abc.file.entry -width 62 -relief sunken\
    -textvariable netstate(abc_open) -font $df

bind .abc.file.entry <KeyRelease> {
    if {[file exists $netstate(abc_open)] && [file isfile $netstate(abc_open)]} {
        load_whole_file $netstate(abc_open)
        title_index $netstate(abc_open)
        focus .abc.titles
	show_titles
       }
}

set w .abc.file.menu
menubutton .abc.file.menu -text file -relief groove -bd 3  -menu $w.type -font $df
menu $w.type -tearoff 0
$w.type add command  -label "browse" -command file_browser  -font $df
$w.type add command  -label "clear recent" -command delete_history  -font $df

for {set i 0} {$i < $netstate(history_length)} {incr i} {
    $w.type add radiobutton  -label $netstate(history$i) \
            -value $i -variable history_index -command process_history -font $df
}

pack .abc.file.menu -side left  -fill x
pack .abc.file.entry -side left  -fill x
pack .abc.file -side top -fill x

set w .abc.functions
button $w.toc -text "TOC" -font $df -relief groove -bd 3 -command show_titles
button $w.header -text "Header" -font $df -relief groove -bd 3\
-command show_header
button $w.cfg -text "Configure" -font $df -command show_config\
-relief groove -bd 3
button $w.v   -text "Voices" -font $df -command show_voice\
-relief groove -bd 3
button $w.src -text "Source" -font $df -relief groove -bd 3\
 -command {copy_selected_tunes_to_html $netstate(outhtml); open_editor}
button $w.rend -text "Render" -font $df -relief groove -bd 3\
 -command  {copy_selected_tunes_to_html $netstate(outhtml); export_to_browser}

button $w.help -text "Help" -font $df -relief groove -bd 3\
 -command open_help_in_browser
pack $w.cfg $w.toc $w.header $w.v $w.src $w.rend $w.help -side left
pack $w

tooltip::tooltip .abc.functions.toc "Table of contents of the opened abc file."
tooltip::tooltip .abc.functions.cfg "Configure the operation of this program."
tooltip::tooltip .abc.functions.header "Edit the formatting parameters of the music notation."
tooltip::tooltip .abc.functions.v "Assign midi programs to the voices "
tooltip::tooltip .abc.functions.src "Generate and edit the html file from the selected tune(s). "
tooltip::tooltip .abc.functions.rend "Generate the html file from the selected\n tune(s) and open in an internet browser."
tooltip::tooltip .abc.functions.help "Opens netabc internet site"
set w .abc.config
frame $w

checkbutton $w.midicheck -text "Include midi data"\
   -variable netstate(mididata) -font $df

grid $w.midicheck -sticky w

radiobutton $w.remote -text "remote javascript" -variable netstate(remote)\
   -value 1 -font $df
radiobutton $w.local -text "local javascript" -variable netstate(remote)\
   -value 0 -font $df -command check_for_js_folder
grid $w.remote $w.local -sticky w

button $w.browserbut -text "select browser" -command "setpath browser"\
    -font $df
entry $w.browser_entry -width 56 -relief sunken\
   -textvariable netstate(browser) -font $df
grid  $w.browserbut $w.browser_entry  -sticky w

button $w.editbut -text "select text editor" -font $df\
   -command "setpath editor"
entry $w.editor -width 56 -relief sunken -textvariable netstate(editor)\
   -font $df
grid $w.editbut $w.editor -sticky w

button $w.javascriptlib -text "path to local javascript" -command setpathjslib\
-font $df
entry $w.jslib -width 56 -relief sunken -textvariable netstate(jslib)\
-font $df
bind .abc.config.jslib <KeyRelease> {
   update_url_pointer
   }
grid $w.javascriptlib $w.jslib -sticky w

button $w.outbut -text "output html file" -font $df\
    -command "setpath outhtml"
entry $w.outhtml -width 56 -relief sunken -textvariable netstate(outhtml)\
   -font $df
grid $w.outbut $w.outhtml -sticky w

label $w.weblab -text "web interface" -font $df
frame $w.webfrm 
radiobutton $w.webfrm.1 -text "abcweb-1" -variable netstate(webscript)\
   -value 1 -font $df
radiobutton $w.webfrm.2 -text "abcweb1-1" -variable netstate(webscript)\
   -value 2 -font $df 
#radiobutton $w.web3 -text "abcweb2-1" -variable netstate(webscript)\
#   -value 3 -font $df 
grid $w.webfrm.1 $w.webfrm.2 -sticky w
grid $w.weblab $w.webfrm -sticky w
label $w.enclab -text "enclose abc" -font $df
frame $w.encfrm
radiobutton $w.encfrm.1 -text "plain" -variable netstate(abcenclose)\
   -value 1 -font $df
radiobutton $w.encfrm.2 -text "<!-- ->" -variable netstate(abcenclose)\
   -value 2 -font $df
radiobutton $w.encfrm.3 -text "div class abc" -variable netstate(abcenclose)\
   -value 3 -font $df
radiobutton $w.encfrm.4 -text "script vnd" -variable netstate(abcenclose)\
   -value 4 -font $df
grid $w.encfrm.1 $w.encfrm.2 $w.encfrm.3 $w.encfrm.4 -sticky w
grid $w.enclab $w.encfrm -sticky w


proc show_config {} {
global exposed_frame
pack forget .abc.$exposed_frame
pack  .abc.config -side top
set exposed_frame config
}

proc open_editor {} {
global netstate
exec $netstate(editor) $netstate(outhtml) &
}

proc show_titles {} {
global exposed_frame
pack forget .abc.$exposed_frame
pack  .abc.titles -side top
set exposed_frame titles
}

proc show_header {} {
global exposed_frame
pack forget .abc.$exposed_frame
pack .abc.header -anchor w
set exposed_frame header
}

proc show_voice {} {
global exposed_frame
pack forget .abc.$exposed_frame
set exposed_frame voice
pack .abc.voice -anchor w
set f .abc.voice.canvas.f
#set child $f.pan1
#tkwait visibility $child
set bbox [grid bbox $f 0 0]
set width [winfo reqwidth .abc]
set height [winfo reqheight $f]
set incr [lindex $bbox 3]
.abc.voice.canvas config -scrollregion "0 0 $width $height"
.abc.voice.canvas config -yscrollincrement $incr
set height [expr $incr * 10]
.abc.voice.canvas  config -width $width -height $height
$f config -height $height
}


###    Table of Contents  - title index   ###
#puts [ttk::style element names]
ttk::style configure Treeview.Heading -font $df
ttk::style configure Treeview -background lavender
ttk::treeview .abc.titles.t -columns {refno key meter title}  -height 1\
        -show headings  \
        -selectmode extended -yscrollcommand {.abc.titles.ysbar set}
foreach col {refno key meter}  name {refnumb keysignature meter}  {
    .abc.titles.t heading $col -text $col
    .abc.titles.t heading $col -command [list SortBy $col 0]
    .abc.titles.t column $col -width [expr [font measure $df $name] +3]
}
.abc.titles.t heading title -text title
.abc.titles.t heading title -command [list SortBy title 0]
.abc.titles.t column title -width [font measure $df "WWWWWWWWWWWWWWWWWWWWWWWW"]


scrollbar .abc.titles.ysbar -bd 2 -command {.abc.titles.t yview}
pack .abc.titles.ysbar -side right -fill y
pack .abc.titles.t  -expand y -fill both
pack .abc.titles
pack .abc           -expand y -fill both
focus .abc.titles.t
set exposed_frame titles

# if running on local make sure that there is a javascript
# folder in the same location where netabc.tcl is running.
proc check_for_js_folder {} {
global netstate
set local_warning "
This will not work. You require a folder containing\
a library of javascript files that are needed to convert\
the abc notation into svg (scaled vector graphics).\
You can find a working copy of this library in the archive\
js.zip in https://~seymour/netabc/.\n\n\
A more recent version of this library is available in
http://abcplus.sourceforge.net/. Look for Portable/abc2svg."

if {[file exist $netstate(jslib)/abcweb-1.js]} return
show_message_page $local_warning word
}

# pop up a new window with a message
proc show_message_page {text wrapmode} {
    global active_sheet df
    #remove_old_sheet
    set p .notice
    if [winfo exist .notice] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        $p.t insert end $text
        #   $p.t configure -state disabled -wrap $wrapmode
    } else {
        toplevel $p
        text $p.t -height 15 -width 50 -wrap $wrapmode -font $df -yscrollcommand {.notice.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -fill both -expand true
        $p.t insert end $text
        #   $p.t configure -state disabled
    }
    raise $p .
}


proc file_browser {} {
    global netstate
    set types {{{abc files} {*.abc}}}

    set filedir [file dirname $netstate(abc_open)]
    set openfile [tk_getOpenFile -initialdir $filedir \
            -filetypes $types]
    open_abc_file $openfile
}

proc setpath {path_var} {
    global netstate

    set filedir [file dirname $netstate($path_var)]
    set openfile [tk_getOpenFile -initialdir $filedir]
    if {[string length $openfile] > 0} {
        set netstate($path_var) $openfile
        update
    }
}

proc setpathjslib {} {
    global netstate
    set filedir [file dirname $netstate(jslib)]
    set openfile [tk_chooseDirectory]
    if {[string length $openfile] > 0} {
        set netstate(jslib) $openfile
        update
    }
    update_url_pointer
}

proc update_url_pointer {} {
    global netstate
    global urlpointer
    set urlpointer(2) $netstate(jslib)/ 
    }




proc open_abc_file {filename} {
    global netstate
    if {[string length $filename] > 0} {
        #       if {[string equal $filename $netstate(abc_open)]} return
        set netstate(abc_open) $filename
        .abc.file.entry xview moveto 1.0
        load_whole_file $netstate(abc_open)
        title_index $netstate(abc_open)
        update_history $filename
	show_titles
    }
}

proc load_whole_file {filename} {
    global wholefile
    global netstate
    #puts "load_whole_file = $filename"
    set inhandle [open $filename rb]
    # title_index uses gets to read the file and ignores \r.
    # In order that wholefile looks the same we replace \r\n with \n.
    # 2017-05-05. This may not work with the Mac.
    fconfigure $inhandle -encoding $netstate(encoder) -translation lf
    set wholefile [read $inhandle]
    close $inhandle
    }

proc update_history {openfile} {
    global netstate
    global history_index
    global df

    #check if file is in history
    for {set i 0} {$i < $netstate(history_length)} {incr i} {
        if {[string compare $netstate(history$i) $openfile] ==  0} return
    }

    if {$netstate(history_length) == 0}  {
        .abc.file.menu.type add radiobutton  -value 0 -font $df\
                -variable history_index -command process_history
    }

    # push history down open stack
    for {set i $netstate(history_length)} {$i > 0} {incr i -1}  {
        set j [expr $i -1]
        set k [expr $i +2]
        set netstate(history$i) $netstate(history$j)
        if {$netstate(history_length) < 10 && $i == $netstate(history_length) } {
            .abc.file.menu.type add radiobutton  -label $netstate(history$i) \
                    -value $i -variable history_index\
                    -font $df -command process_history
        } else {
            .abc.file.menu.type entryconfigure  $k -label $netstate(history$j)
        }
    }
    set netstate(history0) $openfile
    .abc.file.menu.type entryconfigure 2 -label $netstate(history0)
    if {$netstate(history_length) < 10} {incr netstate(history_length)}
}

proc process_history {} {
    global netstate
    global history_index
    if {![file exist $netstate(history$history_index)]} {
        show_message_page\
                "can't read input abc file\n$netstate(history$history_index)" word
        return
    }
    set netstate(abc_open) $netstate(history$history_index)
    .abc.file.entry xview moveto 1.0
    load_whole_file $netstate(abc_open)
    title_index $netstate(abc_open)
    show_titles
    update
}


proc delete_history {} {
global netstate
for {set i 1} {$i < $netstate(history_length)} {incr i} {
  unset netstate(history$i)}
.abc.file.menu.type delete 3 [expr $netstate(history_length) + 2]
set netstate(history_length) 1
}


#
# the function scans the entire abcfile making a list of titles and
# storing the file location of each tune. Code X: T: must begin on the
# first character position of a line.
#
proc title_index {abcfile} {
    global fileseek netstate
    global item_id
    global index_done
    global df
    global midi_header
    global ps_header

    if {[info exist itemposition]} {unset itemposition}
    if {[info exist first_title_item]} {unset first_title_item}
    #    puts "title_index [info level 0]"
    set srch X
    set pat {[0-9]+}
    #.abc.titles.t selection set {}
    .abc.titles.t delete [.abc.titles.t children {}]
    set titlehandle [open $abcfile r]
    fconfigure $titlehandle -encoding $netstate(encoder)
    set filepos 0
    set meter 4/4
    set i 1
    .abc.titles.t tag configure tune -font $df

    #extract any %%MIDI commands in the header
    set midi_header {}
    set ps_header {}
    set nchildren 0
    while {[gets $titlehandle line] >= 0} {
        if {[string index $line 0] == "X"} {
            regexp $pat $line number
            if {$number != 0} {set number [string trimleft $number 0]}
            # 2017-05-05 set filepos
            set filepos [expr [tell $titlehandle] - [string length $line] -2]
	    if {$filepos < 0} {set filepos 0}
            set srch T
            break
            }
        if {[string first "%%MIDI" $line] == 0 } {
            append midi_header $line\n
        } elseif {[string first "%%" $line] == 0 } {
            append ps_header $line\n
            if {[string first "%%beginps" $line] == 0} {
              while {[gets $titlehandle line] >= 0} {
                  append ps_header $line\n
                  if {[string first "%%endps" $line] == 0} break
                  }
             }
        }
    }


    while {[gets $titlehandle line] >= 0} {
        if {!$netstate(blank_lines) && [string length $line] < 1} {set srch X}
        if {[string index $line 0] == "M"} {
            set meter [string range $line 2 end]
            set meter [string trim $meter]
        }
        switch -- $srch {
            X {if {[string compare -length 2 $line "X:"] == 0} {
                    regexp $pat $line  number
            # in case the number has leading zero's eg 0035
            # to be compatible with C programs (eg abcmatch.c).
                    if {$number != 0} {set number [string trimleft $number 0]}
                    set srch T
                } else {
                    set filepos [tell $titlehandle]
                }
            }
            T {
                if {[string index $line 0] == "T" || [string index $line 0] == "P"} {
                    set name [string range $line 2 end]
                    set name [string trim $name]
                    set srch K
                }
            }
            K {
                if {[string index $line 0] == "K"} {
                    set keysig [string range $line 2 end]
                    set keysig [string trim $keysig]
                    set keysig [string range $keysig 0 15]
                    set outline [format "%4s  %-5s %s %s" $number [list $keysig] $meter [list $name]]
                    set toc_index [.abc.titles.t insert {}  end -values $outline -tag tune]
                    incr nchildren
                    if {$netstate(index_by_position)} {
                       set item_id($i) $toc_index
                       #puts "$abcfile item_id($i) = $item_id($i)"
                       } else {
                       set item_id($number) $toc_index
                       #puts "$abcfile item_id($number) = $item_id($number)"
                       }
                    #puts "$i $toc_index"
                    set fileseek($toc_index) $filepos
                    if {![info exist first_title_item]} {
                        .abc.titles.t focus $toc_index
                        .abc.titles.t selection set $toc_index
                        set first_title_item $toc_index
                        update
                    }
                    
                    
                    set srch X
                    incr i
                    if {[expr $i % 20] == 0} update
                }
            }
        }
    }
    if {$nchildren > 15} {set nchildren 15}
    .abc.titles.t configure -height $nchildren
    close $titlehandle
    if {$i == 0} {show_error_message "corrupted file $netstate(abc_open)\nno K:,X:,T: found in file."
        return}
    if {[info exist itemposition] && [info exist item_id($itemposition)]} {
         #puts "item id for $itemposition = $item_id($itemposition)"
        .abc.titles.t selection set $item_id($itemposition)
        .abc.titles.t see $item_id($itemposition)
    }
    update
    set ps_header [string trimright $ps_header]
}

proc SortBy {col direction} {
    set data {}
    foreach row [.abc.titles.t children {}] {
        lappend data [list [.abc.titles.t set $row $col] $row]
    }
    
    set dir [expr {$direction ? "-decreasing" : "-increasing"}]
    set r -1
    
    
    
    # Now reshuffle the rows into the sorted order
    foreach info [lsort -dictionary -index 0 $dir $data] {
        .abc.titles.t  move [lindex $info 1] {} [incr r]
    }
    # Switch the heading so that it will sort in the opposite direction
    .abc.titles.t heading $col -command [list SortBy  $col [expr {!$direction}]]
    
}


# returns position in list

global tunestart tuneend

proc title_selected {} {
    global netstate
    global fileseek
    global tunestart


    set index [.abc.titles.t selection]
    #puts "title_selected =  [winfo exist .live]"
    #puts "title_selected index = $index"
    # in case index is a list 
    set xref [lindex [.abc.titles.t item [lindex $index 0] -values] 0]
    #puts "xref = $xref"
    return $index
}



set abc_header "
%abc-2.2
%%pagewidth 21cm
%%pageheight 27.9cm
%%topmargin 1.0cm
%%botmargin 0.5cm
%%leftmargin 0.8cm
%%rightmargin 0.8cm
%%scale 0.67
%%bgcolor white
%%topspace 0
%%staffsep 2.5cm
%%sysstaffsep 1.5cm
%%measurenb 0
%%composerspace 0
"

global header_array

proc abc_header_to_array {abc_header} {
global header_array
set abc_header [split $abc_header '\n']
array unset header_array
foreach line $abc_header {
   if {[string range $line 0 1] != "%%"} continue
   set firstspace [string first " " $line]
   set endloc [expr $firstspace -1]
   set param [string range $line 0 $endloc]
   set valuestart [expr $firstspace + 1] 
   set valueend [string length $line]
   incr valueend -1
   set value [string range $line $valuestart $valueend]
   set header_array($param) $value
   }
}

proc write_netheader_ini {} {
global header_array
set handle [open netheader.ini w]
foreach item [lsort [array names header_array]] {
   puts $handle "$item $header_array($item)"
   }
   close $handle
}

proc read_netheader_ini {} {
global header_array
if {![file exist netheader.ini]} return
set handle [open netheader.ini r]
while {[gets $handle line] >= 0} {
   set param [lindex $line 0]
   set header_array($param) [lindex $line 1]
   }
close $handle
}

if {[file exist netheader.ini]} {
  read_netheader_ini} else {
  abc_header_to_array $abc_header
  }

frame .abc.header

# this function is not needed right now
proc close_header {} {
foreach w [winfo children .abc.header] {
  destroy $w
  }
pack forget .abc.header 
pack .abc.titles
}

proc create_header_frame {} {
global header_array
global df
global netstate
set names [array names header_array]
set w .abc.header
foreach c [winfo children $w] {destroy $c}
button $w.reset -text "reset to initial settings" -command reset_abc_header -font $df
grid $w.reset
set i 1
foreach name $names {
  label $w.lab$i -text $name -font $df -width 20
  entry $w.ent$i -text header_array($name) -font $df -width 20 
  grid  $w.lab$i $w.ent$i -sticky w
  incr i
  }
label $w.brklab -text "ignore line breaks" -font $df
checkbutton $w.brkchk -text ""  -variable netstate(eol) -font $df
grid $w.brklab $w.brkchk -sticky w
return $i
}

proc reset_abc_header {} {
global abc_header
abc_header_to_array $abc_header
create_header_frame
}

create_header_frame

proc make_abc_header_from_array {} {
global header_array 
global musicfont
global netstate
#set abc_header %abc2.2\n
set abc_header "\n"
set names [array names header_array]
foreach name $names {
  append abc_header "$name $header_array($name)\n"
  }
if {$netstate(eol)} {append abc_header "%%linebreak <none>\n"}
return $abc_header
}


set urlpointer(0) "https://boubounet.fr/misc/" 
set urlpointer(1) "http://moinejf.free.fr/js/"
set urlpointer(2) $netstate(jslib)/ 

proc make_js_script_list {url abcweb} {
set scriptlist "	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>\n"
set styleblock "
        <style type=\"text/css\">
        svg {display:block}
        @media print{body{margin:0;padding:0;border:0}.nop{display:none}}
        </style>"
set w(0) "abc2svg-1.js"
set w(1) "snd-1.js"
set w(2) "follow-1.js"
set tail "\"></script>\n"
append scriptlist "	<script src=\"$url$w(0)$tail"
append scriptlist "	<script src=\"$url$abcweb$tail"
append scriptlist "	<script src=\"$url$w(1)$tail"
append scriptlist "	<script src=\"$url$w(2)$tail"
append scriptlist $styleblock
return $scriptlist
}



proc update_preface {} {
   global netstate
   global abc_header
   #global midi_header
   global ps_header
   global musicfont
   global urlpointer


   set html_preamble "<!DOCTYPE HTML>\n<html>\n<head>
"
   switch $netstate(webscript) {
     1 {set abcweb abcweb-1.js}
     2 {set abcweb abcweb1-1.js}
     3 {set abcweb abcweb2-1.js}
     }

   set remote_svg_script [make_js_script_list $urlpointer(1) $abcweb]
   set local_svg_script  [make_js_script_list $urlpointer(2) $abcweb]

   set preface $html_preamble
   if {$netstate(remote)} {
     set preface $preface$remote_svg_script
     } else {
     set preface $preface$local_svg_script
     }

   switch $netstate(abcenclose) {
	1 {append preface "</head>\n<body>\n%abc-2.2\n"}
	2 {append preface "</head>\n<body>\n%abc-2.2<!--\n"}
	3 {append preface "</head>\n<body>\n<div class=\"abc\">"}
	4 {append preface "</head>\n<body>\n<script type=\"text/vnd.abc\" class=\"abc\">"}
}


   set revised_abc_header [make_abc_header_from_array] 
   set preface $preface$revised_abc_header
   if {[string length $ps_header] > 2} {
	set preface $preface$ps_header}
   return $preface
}



# finds X: command or else returns nothing if eof
proc find_X_code {handle} {
    set line 1
    while {[string index $line 0] != "X" && [eof $handle] !=1} {
        set line [get_nonblank_line $handle]
    }
    return $line
}


proc get_nonblank_line {handle} {
    set line ""
    while {[string length $line] == 0 && [eof $handle] != 1} {
        gets $handle line
    }
    return $line
}

proc get_next_line {handle} {
    gets $handle line
    return $line
}


proc copy_selected_tunes_to_html {filename} {
    #copies or appends all selected tunes to an output file
    global fileseek  exec_out
    global ps_header
    global netstate
    for {set i 0} {$i < 17} {incr i} {
      if {$netstate(mididata)} {
       set addmidi($i) 1
       } else {
       set addmidi($i) 0
       }
    }

    set preface [update_preface]
    set sel [title_selected]
    set edithandle [open $netstate(abc_open) r]
    set outhandle [open $filename w]
    puts $outhandle $preface
    set exec_out "copying $sel to $filename"
    foreach i $sel {
        set loc $fileseek($i)
        seek $edithandle $loc
        set line [find_X_code $edithandle]
        puts $outhandle $line
        incr n
        while {[string length $line] > 0 } {
            if {$netstate(blank_lines)} {
                set line  [get_nonblank_line $edithandle]} else {
                set line  [get_next_line $edithandle]
	        }
            if {[string index $line 0] == "X"} break;
            puts $outhandle $line
	    set loc [string first "V:" $line]
# The procedure does not handle V: enclosed in brackets
	    if {$loc ==0} {
              incr loc 2
	      set payload [string range $line $loc end]
	      set payload [string trimleft $payload]
	      set vcode [lindex [split $payload] 0]
              if {[string is integer $vcode] != 1} {
                   set vc [vcode2numb $vcode]
                   } else {
                   scan $line "V:%d" vc
	           }

	      if {$addmidi($vc)} {
                 puts $outhandle "%%MIDI program $netstate(voice$vc)"
		 puts $outhandle "%%MIDI control 7 $netstate(lvoice$vc)"
		 puts $outhandle "%%MIDI control 10 $netstate(pvoice$vc)"
		 set addmidi($vc) 0
	         }
              }
            if {[string first "K:" $line] && $addmidi(0) == 1} {
                 puts $outhandle "%%MIDI program $netstate(voice0)"
		 puts $outhandle "%%MIDI control 7 $netstate(lvoice0)"
		 puts $outhandle "%%MIDI control 10 $netstate(pvoice0)"
		 set addmidi(0) 0
	         }

         }
	      
	 puts $outhandle "\n"
    }
    switch $netstate(abcenclose) {
       1 {puts $outhandle "\n</body>\n</html>\n"}
       2 {puts $outhandle "\n-->\n</body>\n</html>\n"}
       3 {puts $outhandle "<\div>\n</body>\n</html>\n"}
       4 {puts $outhandle  "</script>\n</body>\n</html>\n"}
       }
    close $edithandle
    close $outhandle
}

proc export_to_browser {} {
    global netstate
    exec $netstate(browser) file://$netstate(outhtml) &
    }

proc open_help_in_browser {} {
    global netstate
    exec $netstate(browser) "https://ifdo.ca/~seymour/netabc/" &
    }


# voice interface

# General Midi Program Definition

set m(1) {"0 Acoustic Grand" "1 Bright Acoustic" "2 Electric Grand" \
            "3 Honky-Tonk" "4 Electric Piano 1" "5 Electric Piano 2" "6 Harpsichord" \
            "7 Clav" }

set m(2) {" 8 Celesta" " 9 Glockenspiel" "10 Music Box" "11 Vibraphone" "12 Marimba" \
            "13 Xylophone" "14 Tubular Bells" "15 Dulcimer"}

set m(3) {"16 Drawbar Organ" "17 Percussive Organ" "18 Rock Organ" \
            "19 Church Organ" "20 Reed Organ" "21 Accordian" "22 Harmonica" "23 Tango Accordian"}

set m(4) { "24 Acoustic Guitar (nylon)" "25 Acoustic Guitar (steel)" \
            "26 Electric Guitar (jazz)" "27 Electric Guitar (clean)" \
            "28 Electric Guitar (muted)" "29 Overdriven Guitar" \
            "30 Distortion Guitar" "31 Guitar Harmonics"}

set m(5) {"32 Acoustic Bass" "33 Electric Bass (finger)" \
            "34 Electric Bass (pick)" "35 Fretless Bass" "36 Slap Bass 1" \
            "37 Slap Bass 2" "38 Synth Bass 1" "39 Synth Bass 2" }

set m(6) { "40 Violin" "41 Viola" "42 Cello" "43 Contrabass" "44 Tremolo Strings" \
            "45 Pizzicato Strings" "46 Orchestral Strings" "47 Timpani" }

set m(7) { "48 String Ensemble 1" "49 String Ensemble 2" "50 SynthStrings 1" \
            "51 SynthStrings 2" "52 Choir Aahs" "53 Voice Oohs" "54 Synth Voice" "55 Orchestra Hit" }

set m(8) { "56 Trumpet" "57 Trombone" "58 Tuba" "59 Muted Trumpet" "60 French Horn" \
            "61 Brass Section" "62 SynthBrass 1" "63 SynthBrass 2"}

set m(9) { "64 Soprano Sax" "65 Alto Sax" "66 Tenor Sax" "67 Baritone Sax" \
            "68 Oboe" "69 English Horn" "70 Bassoon" "71 Clarinet" }

set m(10) { "72 Piccolo" "73 Flute" "74 Recorder" "75 Pan Flute" "76 Blown Bottle" \
            "77 Skakuhachi" "78 Whistle" "79 Ocarina" }

set m(11) { "80 Lead 1 (square)" "81 Lead 2 (sawtooth)" "82 Lead 3 (calliope)" \
            "83 Lead 4 (chiff)" "84 Lead 5 (charang)" "85 Lead 6 (voice)" \
            "86 Lead 7 (fifths)" "87 Lead 8 (bass+lead)"}

set m(12) { "88 Pad 1 (new age)" "89 Pad 2 (warm)" "90 Pad 3 (polysynth)" \
            "91 Pad 4 (choir)" "92 Pad 5 (bowed)" "93 Pad 6 (metallic)" "94 Pad 7 (halo)" \
            "95 Pad 8 (sweep)" }

set m(13) { " 96 FX 1 (rain)" " 97 (soundtrack)" " 98 FX 3 (crystal)" \
            " 99 FX 4 (atmosphere)" "100 FX 5 (brightness)" "101 FX 6 (goblins)" \
            "102 FX 7 (echoes)" "103 FX 8 (sci-fi)" }

set m(14) { "104 Sitar" "105 Banjo" "106 Shamisen" "107 Koto" "108 Kalimba" \
            "109 Bagpipe" "110 Fiddle" "111 Shanai"}

set m(15) { "112 Tinkle Bell" "113 Agogo" "114 Steel Drums" "115 Woodblock" \
            "116 Taiko Drum" "117 Melodic Tom" "118 Synth Drum" "119 Reverse Cymbal" }

set m(16) { "120 Guitar Fret Noise" "121 Breath Noise" "122 Seashore" \
            "123 Bird Tweet" "124 Telephone ring" "125 Helicopter" "126 Applause" "127 Gunshot" }


# voice interface

frame .abc.voice 

button .abc.voice.voicereset -text "Reset all" -command reset_midi_voice -font $df
pack .abc.voice.voicereset -side top -anchor nw
canvas .abc.voice.canvas -width 180 -height 20\
        -yscrollcommand [list .abc.voice.yscroll set]
scrollbar .abc.voice.yscroll -orient vertical \
        -command [list .abc.voice.canvas yview]
pack  .abc.voice.yscroll -side right -fill y
pack  .abc.voice.canvas -side left

set w [frame .abc.voice.canvas.f -bd 0]
.abc.voice.canvas create window 0 0 -window $w -anchor nw

label $w.head0 -text V: -font $df
label $w.head1 -text program -font $df
label $w.head2 -text level -font $df
label $w.head3 -text pan -font $df

for {set i 0} {$i <17} {incr i} {
    label $w.lab$i -text $i -font $df
    set i1 [expr int(1 + $netstate(voice$i)/8)]
    set i2 [expr $netstate(voice$i) % 8 ]
    button $w.prog$i -text [lindex $m($i1) $i2]  -font $df -width 20 -pady 1
    eval {bind $w.prog$i <Button> [list voice_button $i %X %Y]}
    scale $w.pan$i -from 0 -to 127 -length 144  \
            -width 8 -orient horizontal  -showvalue true \
            -variable netstate(pvoice$i) -font $df
    scale $w.vol$i -from 0 -to 127 -length 144  \
            -width 8 -orient horizontal  -showvalue true \
            -variable netstate(lvoice$i) -font $df
}


proc voice_button {num X Y} {
    global window chan
    set window .abc.voice.canvas.f.prog$num
    set chan voice$num
    program_popup $X $Y}

grid   $w.head0 $w.head1 $w.head2 $w.head3
for {set i 0} {$i < 17} {incr i} {
    grid   $w.lab$i  $w.prog$i  $w.vol$i $w.pan$i  -sticky w
}


proc program_popup {rootx rooty} {
    global m df
    
    if {![winfo exists .patchmap]} {
        set instrum_family {piano "chrom percussion" organ guitar bass \
                    strings ensemble brass reed pipe "synth lead" "synth pad" \
                    "synth effects" ethnic percussive "sound effects"}
        set w .patchmap
        menu $w -tearoff 0
        set i 1
        foreach class $instrum_family {
            $w add cascade  -label $class -menu $w.$i -font $df
            set w2 .patchmap.$i
            menu $w2 -tearoff 0
            set j 0
            foreach inst $m($i) {
                $w2 add radiobutton -label $inst \
                        -command "program_select  $i $j " -font $df
                incr j
            }
            incr i
        }
    }
    tk_popup .patchmap $rootx $rooty
}

proc program_select {p1 p2} {
    global netstate chan window m
    
    #  puts "program_select $p1 $p2"
    set netstate($chan) [expr ($p1-1)*8 + $p2]
    #  set name [.patchmap.$p1 entrycget $p2 -label]
    set name [lindex $m($p1) $p2]
    $window configure -text $name
}

proc reset_midi_voice {} {
global netstate
global m
set w  .abc.voice.canvas.f 
for {set i 0} {$i <= 16} {incr i} {
     set netstate(lvoice$i) 64
     set netstate(voice$i) 0
     set netstate(pvoice$i) 64
     set i1 [expr int(1 + $netstate(voice$i)/8)]
     set i2 [expr $netstate(voice$i) % 8 ]
     $w.prog$i configure -text [lindex $m($i1) $i2]
     update
    }
}

if {[file exists $netstate(abc_open)] && [file isfile $netstate(abc_open)]} {
        load_whole_file $netstate(abc_open)
        title_index $netstate(abc_open)
        focus .abc.titles
	show_titles
       } else {
    set msg "Please click file/browse and select an input abc file"
    tk_messageBox -message $msg  -type ok
    }
