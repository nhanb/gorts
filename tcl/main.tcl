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

#set OS [lindex $tcl_platform(os) 0]
#if {$OS == "Windows"} {
    #ttk::style theme use vista
#} elseif {$OS == "Darwin"} {
    #ttk::style theme use aqua
#} else {
    #ttk::style theme use clam
#}
ttk::style theme use clam

wm protocol . WM_DELETE_WINDOW {
    exit 0
}

# GUI

ttk::frame .c -padding 5
ttk::frame .c.description
ttk::label .c.description.lbl -text "Match description"
ttk::entry .c.description.entry -textvariable description
ttk::frame .c.players
ttk::label .c.players.p1lbl -text "Player 1"
ttk::combobox .c.players.p1name -textvariable p1name -width 35
ttk::combobox .c.players.p1country -textvariable p1country -width 5
ttk::spinbox .c.players.p1score -textvariable p1score -from 0 -to 999 -width 4
ttk::button .c.players.p1win -text "▲ Win" -width 6 -state disabled
ttk::label .c.players.p1teamlbl -text "Team 1"
ttk::combobox .c.players.p1team -textvariable p1team
ttk::separator .c.players.separator -orient horizontal
ttk::label .c.players.p2lbl -text "Player 2"
ttk::combobox .c.players.p2name -textvariable p2name -width 35
ttk::combobox .c.players.p2country -textvariable p2country -width 5
ttk::spinbox .c.players.p2score -textvariable p2score -from 0 -to 999 -width 4
ttk::button .c.players.p2win -text "▲ Win" -width 6 -state disabled
ttk::label .c.players.p2teamlbl -text "Team 2"
ttk::combobox .c.players.p2team -textvariable p2team
ttk::frame .c.buttons
ttk::button .c.buttons.apply -text "▶ Apply" -command applystate
ttk::button .c.buttons.discard -text "✖ Discard" -state disabled
ttk::button .c.buttons.reset -text "↶ Reset scores" -state disabled
ttk::button .c.buttons.swap -text "⇄ Swap players" -state disabled
ttk::label .c.status -textvariable mainstatus

grid .c -row 0 -column 0 -sticky NESW
grid .c.description -row 0 -column 0 -sticky NESW -pady {0 5}
grid .c.description.lbl -row 0 -column 0 -padx {0 5}
grid .c.description.entry -row 0 -column 1 -sticky EW
grid columnconfigure .c.description 1 -weight 1
grid .c.players -row 1 -column 0
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
grid .c.buttons -row 2 -column 0 -sticky W -pady {10 0}
grid .c.buttons.apply -row 0 -column 0
grid .c.buttons.discard -row 0 -column 1
grid .c.buttons.reset -row 0 -column 2
grid .c.buttons.swap -row 0 -column 3
grid .c.status -row 3 -column 0 -columnspan 5 -pady {10 0} -sticky EW

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
    set ::description [gets stdin]
    set ::p1name [gets stdin]
    set ::p1country [gets stdin]
    set ::p1score [gets stdin]
    set ::p1team [gets stdin]
    set ::p2name [gets stdin]
    set ::p2country [gets stdin]
    set ::p2score [gets stdin]
    set ::p2team [gets stdin]
    update_applied_state
}

proc applystate {} {
    puts "applystate"
    puts $::description
    puts $::p1name
    puts $::p1country
    puts $::p1score
    puts $::p1team
    puts $::p2name
    puts $::p2country
    puts $::p2score
    puts $::p2team
    update_applied_state
}

set ::checkfunctions {}
proc update_applied_state {} {
    set ::applied_description $::description
    set ::applied_p1name $::p1name
    set ::applied_p1country $::p1country
    set ::applied_p1score $::p1score
    set ::applied_p1team $::p1team
    set ::applied_p2name $::p2name
    set ::applied_p2country $::p2country
    set ::applied_p2score $::p2score
    set ::applied_p2team $::p2team
    foreach f $::checkfunctions { $f "" "" "" }
}

proc setupdiffcheck {} {
    # Define styling for "dirty"
    foreach x {TEntry TCombobox TSpinbox} {
        ttk::style configure Dirty.${x} -fieldbackground #dffcde
    }

    # I _really_ need to properly learn how scopes and variables work
    proc checkdescription {_ _ _} {
        if {$::description == $::applied_description} {
            .c.description.entry configure -style TEntry
        } else {
            .c.description.entry configure -style Dirty.TEntry
        }
    }
    proc checkp1name {_ _ _} {
        if {$::p1name == $::applied_p1name} {
            .c.players.p1name configure -style TCombobox
        } else {
            .c.players.p1name configure -style Dirty.TCombobox
        }
    }
    proc checkp1country {_ _ _} {
        if {$::p1country == $::applied_p1country} {
            .c.players.p1country configure -style TCombobox
        } else {
            .c.players.p1country configure -style Dirty.TCombobox
        }
    }
    proc checkp1score {_ _ _} {
        if {$::p1score == $::applied_p1score} {
            .c.players.p1score configure -style TSpinbox
        } else {
            .c.players.p1score configure -style Dirty.TSpinbox
        }
    }
    proc checkp1team {_ _ _} {
        if {$::p1team == $::applied_p1team} {
            .c.players.p1team configure -style TCombobox
        } else {
            .c.players.p1team configure -style Dirty.TCombobox
        }
    }
    proc checkp2name {_ _ _} {
        if {$::p2name == $::applied_p2name} {
            .c.players.p2name configure -style TCombobox
        } else {
            .c.players.p2name configure -style Dirty.TCombobox
        }
    }
    proc checkp2country {_ _ _} {
        if {$::p2country == $::applied_p2country} {
            .c.players.p2country configure -style TCombobox
        } else {
            .c.players.p2country configure -style Dirty.TCombobox
        }
    }
    proc checkp2score {_ _ _} {
        if {$::p2score == $::applied_p2score} {
            .c.players.p2score configure -style TSpinbox
        } else {
            .c.players.p2score configure -style Dirty.TSpinbox
        }
    }
    proc checkp2team {_ _ _} {
        if {$::p2team == $::applied_p2team} {
            .c.players.p2team configure -style TCombobox
        } else {
            .c.players.p2team configure -style Dirty.TCombobox
        }
    }
    trace add variable ::description write checkdescription
    trace add variable ::p1name write checkp1name
    trace add variable ::p1country write checkp1country
    trace add variable ::p1score write checkp1score
    trace add variable ::p1team write checkp1team
    trace add variable ::p2name write checkp2name
    trace add variable ::p2country write checkp2country
    trace add variable ::p2score write checkp2score
    trace add variable ::p2team write checkp2team
    set ::checkfunctions {
        checkdescription
        checkp1name
        checkp1country
        checkp1score
        checkp1team
        checkp2name
        checkp2country
        checkp2score
        checkp2team
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
