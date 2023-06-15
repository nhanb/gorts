package require Tk

wm title . "Overly Repetitive Tedious Software (in Go)"
tk appname gorts

set OS [lindex $tcl_platform(os) 0]
if {$OS == "Windows"} {
    ttk::style theme use vista
} elseif {$OS == "Darwin"} {
    ttk::style theme use aqua
} else {
    ttk::style theme use clam
}

ttk::frame .c -padding 5
ttk::frame .c.description
ttk::label .c.description.lbl -text "Match description"
ttk::entry .c.description.entry
ttk::frame .c.players
ttk::label .c.players.p1lbl -text "Player 1"
ttk::combobox .c.players.p1name -width 35
ttk::combobox .c.players.p1country -width 5
ttk::spinbox .c.players.p1score -from 0 -to 999 -width 4
ttk::button .c.players.p1win -text "▲ Win" -width 5
ttk::label .c.players.p1teamlbl -text "Team 1"
ttk::combobox .c.players.p1teamname
ttk::separator .c.players.separator -orient horizontal
ttk::label .c.players.p2lbl -text "Player 2"
ttk::combobox .c.players.p2name -width 35
ttk::combobox .c.players.p2country -width 5
ttk::spinbox .c.players.p2score -from 0 -to 999 -width 4
ttk::button .c.players.p2win -text "▲ Win" -width 5
ttk::label .c.players.p2teamlbl -text "Team 2"
ttk::combobox .c.players.p2teamname
ttk::frame .c.buttons
ttk::button .c.buttons.apply -text "▶ Apply"
ttk::button .c.buttons.discard -text "✖ Discard"
ttk::button .c.buttons.reset -text "↶ Reset scores"
ttk::button .c.buttons.swap -text "⇄ Swap players"

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
grid .c.players.p1teamname -row 1 -column 1 -columnspan 3 -sticky EW
grid .c.players.separator -row 2 -column 0 -columnspan 5 -pady 10 -sticky EW
grid .c.players.p2lbl -row 3 -column 0
grid .c.players.p2name -row 3 -column 1
grid .c.players.p2country -row 3 -column 2
grid .c.players.p2score -row 3 -column 3
grid .c.players.p2win -row 3 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .c.players.p2teamlbl -row 4 -column 0
grid .c.players.p2teamname -row 4 -column 1 -columnspan 3 -sticky EW
grid .c.buttons -row 5 -column 0 -sticky W -pady {10 0}
grid .c.buttons.apply -row 0 -column 0
grid .c.buttons.discard -row 0 -column 1
grid .c.buttons.reset -row 0 -column 2
grid .c.buttons.swap -row 0 -column 3

grid columnconfigure .c.players 2 -pad 5
grid columnconfigure .c.buttons 1 -pad 15
grid columnconfigure .c.buttons 3 -pad 15
