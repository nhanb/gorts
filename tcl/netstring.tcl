proc netstring {s} {
    set len [string length $s]
    return "$len:$s,"
}

proc netstrings {strings} {
    set result ""
    foreach s $strings {
        set result [string cat $result [netstring $s]]
    }
    return [netstring $result]
}

proc readnetstring {chan} {
    set data ""
    set char ""
    while {$char != ":"} {
        set char [read $chan 1]
        set data [string cat $data $char]
    }
    set nslen [string range $data 0 {end-1}]
    set nstr [read $chan $nslen]
    read $chan 1; # consume the trailing ","
    return $nstr
}

# Assumes input is multiple well formed netstrings concatenated.
# Returns list of decoded values.
proc decodenetstrings {ns} {
    set results {}
    while {$ns != ""} {
        set colonIdx [string first : $ns]
        set len [string range $ns 0 [expr { $colonIdx - 1 }]]
        set startIdx [expr {$colonIdx + 1}]
        set endIdx [expr {$startIdx + $len - 1}]
        set str [string range $ns $startIdx $endIdx]
        lappend results $str
        set ns [string range $ns [expr {$endIdx + 2}] end];
    }
    return $results
}
