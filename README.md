# GORTS

![](gorts.png)

[![builds.sr.ht status](https://builds.sr.ht/~nhanb/gorts/commits/master.svg)](https://builds.sr.ht/~nhanb/gorts/commits/master?)

... is [ORTS][1] but in pure Go and pure Tcl/Tk
passing messages through good ole pipes, the way Bell Labs intended.

**GORTS is a work in progress.**
Nothing is guaranteed to work yet. If you need something to use _now_, see
[ORTS][1].

# Download

Go to <https://git.sr.ht/~nhanb/gorts/refs>, click on the latest version
(vX.X.X), download either `GORTS-Linux.zip` or `GORTS-Windows.zip`.

## Windows

Just unzip and run gorts.exe.

## Linux

Dependency: [tk](https://repology.org/project/tk/versions)
(we basically assume `tclsh` is available from $PATH)

Unzip, run `gorts` from the unzipped directory.

Proper packaging is not planned because I only develop on Linux and stream on
Windows. If you want to contribute then I'm happy to give pointers though.

# License

Copyright (C) 2023 Bui Thanh Nhan

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://www.gnu.org/licenses/>.

[1]: https://github.com/nhanb/orts
