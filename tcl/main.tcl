# Tcl on Windows has unfortunate defaults:
#   - cp1252 encoding, which will mangle utf-8 source code
#   - crlf linebreaks instead of unix-style lf
# Let's be consistent cross-platform to avoid surprises:
encoding system "utf-8"
foreach p {stdin stdout stderr} {
    fconfigure $p -encoding "utf-8"
    fconfigure $p -translation lf
}

source -encoding "utf-8" tcl/netstring.tcl

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
    description .n.m.description.entry
    subtitle .n.m.subtitle.entry
    p1name .n.m.players.p1name
    p1country .n.m.players.p1country
    p1score .n.m.players.p1score
    p1team .n.m.players.p1team
    p2name .n.m.players.p2name
    p2country .n.m.players.p2country
    p2score .n.m.players.p2score
    p2team .n.m.players.p2team
}

array set startgg {
    token ""
    slug ""
    msg ""
}

# GUI has 2 tabs: Main (.n.m) and start.gg (.n.s)

ttk::notebook .n
ttk::frame .n.m -padding 5
ttk::frame .n.s -padding 5
.n add .n.m -text Main
.n add .n.s -text start.gg
grid .n -column 0 -row 0 -sticky NESW -padx 3 -pady 3

# Main tab:

ttk::frame .n.m.description
ttk::label .n.m.description.lbl -text "Title"
ttk::entry .n.m.description.entry -textvariable scoreboard(description)
ttk::frame .n.m.subtitle
ttk::label .n.m.subtitle.lbl -text "Subtitle"
ttk::entry .n.m.subtitle.entry -textvariable scoreboard(subtitle)
ttk::frame .n.m.players
ttk::label .n.m.players.p1lbl -text "Player 1"
ttk::combobox .n.m.players.p1name -textvariable scoreboard(p1name) -width 35
ttk::combobox .n.m.players.p1country -textvariable scoreboard(p1country) -width 5
ttk::spinbox .n.m.players.p1score -textvariable scoreboard(p1score) -from 0 -to 999 -width 4
ttk::button .n.m.players.p1win -text "▲ Win" -width 6 -command {incr scoreboard(p1score)}
ttk::label .n.m.players.p1teamlbl -text "Team 1"
ttk::combobox .n.m.players.p1team -textvariable scoreboard(p1team)
ttk::separator .n.m.players.separator -orient horizontal
ttk::label .n.m.players.p2lbl -text "Player 2"
ttk::combobox .n.m.players.p2name -textvariable scoreboard(p2name) -width 35
ttk::combobox .n.m.players.p2country -textvariable scoreboard(p2country) -width 5
ttk::spinbox .n.m.players.p2score -textvariable scoreboard(p2score) -from 0 -to 999 -width 4
ttk::button .n.m.players.p2win -text "▲ Win" -width 6 -command {incr scoreboard(p2score)}
ttk::label .n.m.players.p2teamlbl -text "Team 2"
ttk::combobox .n.m.players.p2team -textvariable scoreboard(p2team)
ttk::frame .n.m.buttons
ttk::button .n.m.buttons.apply -text "▶ Apply" -command applyscoreboard
ttk::button .n.m.buttons.discard -text "✖ Discard" -command discardscoreboard
ttk::button .n.m.buttons.reset -text "↶ Reset scores" -command {
    set scoreboard(p1score) 0
    set scoreboard(p2score) 0
}
ttk::button .n.m.buttons.swap -text "⇄ Swap players" -command {
    foreach key {name country score team} {
        set tmp $scoreboard(p1$key)
        set scoreboard(p1$key) $scoreboard(p2$key)
        set scoreboard(p2$key) $tmp
    }
}
ttk::label .n.m.status -textvariable mainstatus
grid .n.m.description -row 0 -column 0 -sticky NESW -pady {0 5}
grid .n.m.description.lbl -row 0 -column 0 -padx {0 5}
grid .n.m.description.entry -row 0 -column 1 -sticky EW
grid columnconfigure .n.m.description 1 -weight 1
grid .n.m.subtitle -row 1 -column 0 -sticky NESW -pady {0 5}
grid .n.m.subtitle.lbl -row 0 -column 0 -padx {0 5}
grid .n.m.subtitle.entry -row 0 -column 1 -sticky EW
grid columnconfigure .n.m.subtitle 1 -weight 1
grid .n.m.players -row 2 -column 0
grid .n.m.players.p1lbl -row 0 -column 0
grid .n.m.players.p1name -row 0 -column 1
grid .n.m.players.p1country -row 0 -column 2
grid .n.m.players.p1score -row 0 -column 3
grid .n.m.players.p1win -row 0 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .n.m.players.p1teamlbl -row 1 -column 0
grid .n.m.players.p1team -row 1 -column 1 -columnspan 3 -sticky EW
grid .n.m.players.separator -row 2 -column 0 -columnspan 5 -pady 10 -sticky EW
grid .n.m.players.p2lbl -row 3 -column 0
grid .n.m.players.p2name -row 3 -column 1
grid .n.m.players.p2country -row 3 -column 2
grid .n.m.players.p2score -row 3 -column 3
grid .n.m.players.p2win -row 3 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .n.m.players.p2teamlbl -row 4 -column 0
grid .n.m.players.p2team -row 4 -column 1 -columnspan 3 -sticky EW
grid .n.m.buttons -row 3 -column 0 -sticky W -pady {10 0}
grid .n.m.buttons.apply -row 0 -column 0
grid .n.m.buttons.discard -row 0 -column 1
grid .n.m.buttons.reset -row 0 -column 2
grid .n.m.buttons.swap -row 0 -column 3
grid .n.m.status -row 4 -column 0 -columnspan 5 -pady {10 0} -sticky EW
grid columnconfigure .n.m.players 2 -pad 5
grid columnconfigure .n.m.buttons 1 -pad 15
grid columnconfigure .n.m.buttons 3 -pad 15
grid rowconfigure .n.m.players 1 -pad 5
grid rowconfigure .n.m.players 3 -pad 5

# start.gg tab:

#.n select .n.s; # for debug only
ttk::label .n.s.tokenlbl -text "Personal token: "
ttk::entry .n.s.token -show * -textvariable startgg(token)
ttk::label .n.s.tournamentlbl -text "Tournament slug: "
ttk::entry .n.s.tournamentslug -textvariable startgg(slug)
ttk::button .n.s.fetch -text "Fetch players" -command fetchplayers
ttk::label .n.s.msg -textvariable startgg(msg)

grid .n.s.tokenlbl -row 0 -column 0 -sticky W
grid .n.s.token -row 0 -column 1 -sticky EW
grid .n.s.tournamentlbl -row 1 -column 0 -sticky W
grid .n.s.tournamentslug -row 1 -column 1 -sticky EW
grid .n.s.fetch -row 2 -column 1 -stick W
grid .n.s.msg -row 3 -column 1 -stick W
grid columnconfigure .n.s 1 -weight 1
grid rowconfigure .n.s 1 -pad 5

proc initialize {} {
    foreach p {stdin stdout} {
        fconfigure $p -translation binary
    }
    loadicon
    loadstartgg
    loadwebmsg
    loadcountrycodes
    loadscoreboard
    loadplayernames

    setupdiffcheck
    #setupplayersuggestion
}

# Very simple IPC system where Tcl client talks to Go server via stdin/stdout
# using netstrings as wire format.
proc ipc {method args} {
    set payload [concat $method $args]
    puts -nonewline [netstrings $payload]
    flush stdout
    return [decodenetstrings [readnetstring stdin]]
}

proc loadicon {} {
    set resp [ipc "geticon"]
    set iconblob [lindex $resp 0]
    image create photo applicationIcon -data $iconblob
    wm iconphoto . -default applicationIcon
}

proc loadstartgg {} {
    set resp [ipc "getstartgg"]
    set ::startgg(token) [lindex $resp 0]
    set ::startgg(slug) [lindex $resp 1]
}

proc loadwebmsg {} {
    set resp [ipc "getwebport"]
    set webport [lindex $resp 0]
    set ::mainstatus "Point your OBS browser source to http://localhost:${webport}"
}

proc loadcountrycodes {} {
    set codes [ipc "getcountrycodes"]
    .n.m.players.p1country configure -values $codes
    .n.m.players.p2country configure -values $codes
}

proc loadscoreboard {} {
    set sb [ipc "getscoreboard"]
    set ::scoreboard(description) [lindex $sb 0]
    set ::scoreboard(subtitle) [lindex $sb 1]
    set ::scoreboard(p1name) [lindex $sb 2]
    set ::scoreboard(p1country) [lindex $sb 3]
    set ::scoreboard(p1score) [lindex $sb 4]
    set ::scoreboard(p1team) [lindex $sb 5]
    set ::scoreboard(p2name) [lindex $sb 6]
    set ::scoreboard(p2country) [lindex $sb 7]
    set ::scoreboard(p2score) [lindex $sb 8]
    set ::scoreboard(p2team) [lindex $sb 9]
    update_applied_scoreboard
}

proc applyscoreboard {} {
    set sb [ \
        ipc "applyscoreboard" \
        $::scoreboard(description) \
        $::scoreboard(subtitle) \
        $::scoreboard(p1name) \
        $::scoreboard(p1country) \
        $::scoreboard(p1score) \
        $::scoreboard(p1team) \
        $::scoreboard(p2name) \
        $::scoreboard(p2country) \
        $::scoreboard(p2score) \
        $::scoreboard(p2team) \
    ]
    update_applied_scoreboard
}

proc loadplayernames {} {
    set playernames [ipc "searchplayers" ""]
    .n.m.players.p1name configure -values $playernames
    .n.m.players.p2name configure -values $playernames
}

proc setupplayersuggestion {} {
    proc update_suggestions {_ key _} {
        if {!($key == "p1name" || $key == "p2name")} {
            return
        }
        set newvalue $::scoreboard($key)
        set widget .n.m.players.$key
        set matches [searchplayers $newvalue]
        $widget configure -values $matches
    }
    trace add variable ::scoreboard write update_suggestions
}

proc searchplayers {query} {
    set playernames {}
    puts "searchplayers"
    puts $query
    set line [gets stdin]
    while {$line != "end"} {
        lappend playernames $line
        set line [gets stdin]
    }
    return $playernames
}

proc fetchplayers {} {
    .n.s.fetch configure -state disabled
    .n.s.token configure -state disabled
    .n.s.tournamentslug configure -state disabled
    set ::startgg(msg) "Fetching..."
    puts fetchplayers
    puts $::startgg(token)
    puts $::startgg(slug)
}

proc fetchplayers__resp {} {
    set ::startgg(msg) [gets stdin]
    .n.s.fetch configure -state normal
    .n.s.token configure -state normal
    .n.s.tournamentslug configure -state normal
}

proc discardscoreboard {} {
    foreach key [array names ::scoreboard] {
        set ::scoreboard($key) $::applied_scoreboard($key)
    }
}

proc update_applied_scoreboard {} {
    foreach key [array names ::scoreboard] {
        set ::applied_scoreboard($key) $::scoreboard($key)
    }
}

proc setupdiffcheck {} {
    # Define styling for "dirty"
    foreach x {TEntry TCombobox TSpinbox} {
        ttk::style configure "Dirty.$x" -fieldbackground #dffcde
    }

    trace add variable ::scoreboard write ::checkdiff
    trace add variable ::applied_scoreboard write ::checkdiff
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
