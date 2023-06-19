# Tcl on Windows has unfortunate defaults:
#   - cp1252 encoding, which will mangle utf-8 source code
#   - crlf linebreaks instead of unix-style lf
# Let's be consistent cross-platform to avoid surprises:
encoding system "utf-8"
foreach p {stdin stdout stderr} {
    fconfigure $p -encoding "utf-8"
    fconfigure $p -translation lf
}

package require Tk

wm title . "Overly Repetitive Tedious Software (in Go)"
tk appname gorts

# Proper Windows theme doesn't allow setting fieldbackground on text inputs,
# so let's settle with `clam` instead.
ttk::style theme use clam

wm protocol . WM_DELETE_WINDOW {
    exit 0
}

# Data that we send to the actual web-based overlay:
array set scoreboard {
    description ""
    subtitle ""
    p1name ""
    p1country ""
    p1score 0
    p1team ""
    p2name ""
    p2country ""
    p2score 0
    p2team ""
}

# $applied_scoreboard represents data that has actually been applied
# to the overlay. This is used to display diff in the UI, and to restore data
# when user clicks "Discard".
foreach key [array names scoreboard] {
    set applied_scoreboard($key) scoreboard($key)
}

array set var_to_widget {
    description .c.description.entry
    subtitle .c.subtitle.entry
    p1name .c.players.p1name
    p1country .c.players.p1country
    p1score .c.players.p1score
    p1team .c.players.p1team
    p2name .c.players.p2name
    p2country .c.players.p2country
    p2score .c.players.p2score
    p2team .c.players.p2team
}

# GUI

ttk::frame .c -padding 5
ttk::frame .c.description
ttk::label .c.description.lbl -text "Title"
ttk::entry .c.description.entry -textvariable scoreboard(description)
ttk::frame .c.subtitle
ttk::label .c.subtitle.lbl -text "Subtitle"
ttk::entry .c.subtitle.entry -textvariable scoreboard(subtitle)
ttk::frame .c.players
ttk::label .c.players.p1lbl -text "Player 1"
ttk::combobox .c.players.p1name -textvariable scoreboard(p1name) -width 35
ttk::combobox .c.players.p1country -textvariable scoreboard(p1country) -width 5
ttk::spinbox .c.players.p1score -textvariable scoreboard(p1score) -from 0 -to 999 -width 4
ttk::button .c.players.p1win -text "▲ Win" -width 6 -command {incr scoreboard(p1score)}
ttk::label .c.players.p1teamlbl -text "Team 1"
ttk::combobox .c.players.p1team -textvariable scoreboard(p1team)
ttk::separator .c.players.separator -orient horizontal
ttk::label .c.players.p2lbl -text "Player 2"
ttk::combobox .c.players.p2name -textvariable scoreboard(p2name) -width 35
ttk::combobox .c.players.p2country -textvariable scoreboard(p2country) -width 5
ttk::spinbox .c.players.p2score -textvariable scoreboard(p2score) -from 0 -to 999 -width 4
ttk::button .c.players.p2win -text "▲ Win" -width 6 -command {incr scoreboard(p2score)}
ttk::label .c.players.p2teamlbl -text "Team 2"
ttk::combobox .c.players.p2team -textvariable scoreboard(p2team)
ttk::frame .c.buttons
ttk::button .c.buttons.apply -text "▶ Apply" -command applystate
ttk::button .c.buttons.discard -text "✖ Discard" -command discardstate
ttk::button .c.buttons.reset -text "↶ Reset scores" -command {
    set scoreboard(p1score) 0
    set scoreboard(p2score) 0
}
ttk::button .c.buttons.swap -text "⇄ Swap players" -command {
    foreach key {name country score team} {
        set tmp $scoreboard(p1$key)
        set scoreboard(p1$key) $scoreboard(p2$key)
        set scoreboard(p2$key) $tmp
    }
}
ttk::label .c.status -textvariable mainstatus

grid .c -row 0 -column 0 -sticky NESW
grid .c.description -row 0 -column 0 -sticky NESW -pady {0 5}
grid .c.description.lbl -row 0 -column 0 -padx {0 5}
grid .c.description.entry -row 0 -column 1 -sticky EW
grid columnconfigure .c.description 1 -weight 1
grid .c.subtitle -row 1 -column 0 -sticky NESW -pady {0 5}
grid .c.subtitle.lbl -row 0 -column 0 -padx {0 5}
grid .c.subtitle.entry -row 0 -column 1 -sticky EW
grid columnconfigure .c.subtitle 1 -weight 1
grid .c.players -row 2 -column 0
grid .c.players.p1lbl -row 0 -column 0
grid .c.players.p1name -row 0 -column 1
grid .c.players.p1country -row 0 -column 2
grid .c.players.p1score -row 0 -column 3
grid .c.players.p1win -row 0 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .c.players.p1teamlbl -row 1 -column 0
grid .c.players.p1team -row 1 -column 1 -columnspan 3 -sticky EW
grid .c.players.separator -row 2 -column 0 -columnspan 5 -pady 10 -sticky EW
grid .c.players.p2lbl -row 3 -column 0
grid .c.players.p2name -row 3 -column 1
grid .c.players.p2country -row 3 -column 2
grid .c.players.p2score -row 3 -column 3
grid .c.players.p2win -row 3 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .c.players.p2teamlbl -row 4 -column 0
grid .c.players.p2team -row 4 -column 1 -columnspan 3 -sticky EW
grid .c.buttons -row 3 -column 0 -sticky W -pady {10 0}
grid .c.buttons.apply -row 0 -column 0
grid .c.buttons.discard -row 0 -column 1
grid .c.buttons.reset -row 0 -column 2
grid .c.buttons.swap -row 0 -column 3
grid .c.status -row 4 -column 0 -columnspan 5 -pady {10 0} -sticky EW

grid columnconfigure .c.players 2 -pad 5
grid columnconfigure .c.buttons 1 -pad 15
grid columnconfigure .c.buttons 3 -pad 15

# The following procs constitute a very simple line-based IPC system where Tcl
# client talks to Go server via stdin/stdout.

proc initialize {b64icon webport} {
    seticon $b64icon
    set ::mainstatus "Point your OBS browser source to http://localhost:${webport}"
    readstate
    setupdiffcheck
}

proc seticon {b64data} {
    image create photo applicationIcon -data [
        binary decode base64 $b64data
    ]
    wm iconphoto . -default applicationIcon
}

proc readstate {} {
    puts "readstate"
    set ::scoreboard(description) [gets stdin]
    set ::scoreboard(subtitle) [gets stdin]
    set ::scoreboard(p1name) [gets stdin]
    set ::scoreboard(p1country) [gets stdin]
    set ::scoreboard(p1score) [gets stdin]
    set ::scoreboard(p1team) [gets stdin]
    set ::scoreboard(p2name) [gets stdin]
    set ::scoreboard(p2country) [gets stdin]
    set ::scoreboard(p2score) [gets stdin]
    set ::scoreboard(p2team) [gets stdin]
    update_applied_state
}

proc applystate {} {
    puts "applystate"
    puts $::scoreboard(description)
    puts $::scoreboard(subtitle)
    puts $::scoreboard(p1name)
    puts $::scoreboard(p1country)
    puts $::scoreboard(p1score)
    puts $::scoreboard(p1team)
    puts $::scoreboard(p2name)
    puts $::scoreboard(p2country)
    puts $::scoreboard(p2score)
    puts $::scoreboard(p2team)
    update_applied_state
}


proc discardstate {} {
    foreach key [array names ::scoreboard] {
        set ::scoreboard($key) $::applied_scoreboard($key)
        ::checkdiff "" $key ""
    }
}

proc update_applied_state {} {
    foreach key [array names ::scoreboard] {
        set ::applied_scoreboard($key) $::scoreboard($key)
        ::checkdiff "" $key ""
    }
}

proc setupdiffcheck {} {
    # Define styling for "dirty"
    foreach x {TEntry TCombobox TSpinbox} {
        ttk::style configure "Dirty.$x" -fieldbackground #dffcde
    }

    trace add variable ::scoreboard write ::checkdiff
}

proc checkdiff {_ key _} {
    set widget $::var_to_widget($key)
    if {$::scoreboard($key) == $::applied_scoreboard($key)} {
        $widget configure -style [winfo class $widget]
    } else {
        $widget configure -style "Dirty.[winfo class $widget]"
    }
}

# By default this window is not focused and not even brought to
# foreground on Windows. I suspect it's because tcl is exec'ed from Go.
# Minimizing then re-opening it seems to do the trick.
# This workaround, however, makes the window unfocused on KDE, so
# let's only use it on Windows.
if {$tcl_platform(platform) == "windows"} {
    wm iconify .
    wm deiconify .
}
