# GORTS

![](gorts.png)

[![builds.sr.ht status](https://builds.sr.ht/~nhanb/gorts/commits/master.svg)](https://builds.sr.ht/~nhanb/gorts/commits/master?)
[![github status](https://github.com/nhanb/gorts/actions/workflows/release.yml/badge.svg)](https://github.com/nhanb/gorts/actions/workflows/release.yml)

... is [ORTS][1] but in pure Go and pure Tcl/Tk
passing messages through good ole pipes, the way Bell Labs intended.

**GORTS is a work in progress.**
Nothing is guaranteed to work yet. If you need something to use _now_, see
[ORTS][1].

# Download

You can download from either of:

- [SourceHut](https://git.sr.ht/~nhanb/gorts/refs): click on the latest
  version (vX.X.X), download `GORTS-Linux-vX.X.X.zip` or
  `GORTS-Windows-vX.X.X.zip`.
- [GitHub](https://github.com/nhanb/gorts/releases/latest): download
  `GORTS-Linux.zip` or `GORTS-Windows.zip`.

# Use

## Windows

Just unzip and run gorts.exe.

## Linux

Dependency: [tk](https://repology.org/project/tk/versions)
(we basically assume `tclsh` is available from $PATH)

Unzip, run `gorts` from the unzipped directory.

Proper packaging is not planned because I only develop on Linux and stream on
Windows. If you want to contribute then I'm happy to give pointers though.

## macOS or any other unix-like

Unplanned but I'm open to paid work.

# I got a virus warning?

GORTS is written in the Go programing language, which suffers from false
positives more often than usual. See <https://go.dev/doc/faq#virus>:

> Why does my virus-scanning software think my Go distribution or compiled
> binary is infected?
>
> This is a common occurrence, especially on Windows machines, and is almost
> always a false positive. Commercial virus scanning programs are often
> confused by the structure of Go binaries, which they don't see as often as
> those compiled from other languages.

So no, I'm not trying to hackerman you. If you're really concerned, feel free
to audit the code and compile GORTS yourself. There's really not that much
code.

# Compile from source

Can cross-compile from any unix-like. I'm cheating a little though, by
downloading a prebuilt tcl executable for Windows, and just assume Linux users
have already installed tcl/tk.

Prerequisites: `make`, `go`, `curl`, `zip`.

```sh
make dist/GORTS-Linux.zip
make dist/GORTS-Windows.zip
```

See Makefile for details.

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

# Dev notes

Tcl options on Windows:

- [TclKits](https://tclkits.rkeene.org/fossil/wiki/Downloads): single 5.8MiB
  binary <== currently used
- [IronTcl](https://www.irontcl.com): 14.5Mib folder unzipped
- Manually compile? TODO

Web server should probably read state from memory instead of disk (state.json).
Sounds like premature optimization though.

[1]: https://github.com/nhanb/orts
