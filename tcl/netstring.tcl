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
