package main

import (
	"bufio"
	_ "embed"
	"io"
	"log"
	"os/exec"
)

//go:embed tcl/main.tcl
var mainTcl string

func main() {
	tcl := initTcl()
	tcl.Connect()
}

type Tcl struct {
	cmd *exec.Cmd
}

func initTcl() Tcl {
	cmd := exec.Command("tclsh")
	return Tcl{cmd}
}

func (t *Tcl) Connect() {
	stdout, err := t.cmd.StdoutPipe()
	if err != nil {
		panic(err)
	}

	stdin, err := t.cmd.StdinPipe()
	if err != nil {
		panic(err)
	}

	err = t.cmd.Start()
	if err != nil {
		panic(err)
	}

	io.WriteString(stdin, mainTcl)
	println("Loaded main tcl script.")

	io.WriteString(stdin, "readvars\n")

	reqscanner := bufio.NewScanner(stdout)
	for reqscanner.Scan() {
		req := reqscanner.Text()
		println("=> " + req)
		switch req {
		case "readvars":
			for _, line := range serveReadvars() {
				println("<= " + line)
				io.WriteString(stdin, line+"\n")
			}
		default:
			println("Skipping bogus command: " + req)
		}
	}

	println("Tcl process terminated.")

	if err := reqscanner.Err(); err != nil {
		log.Fatal(err)
	}
}

func serveReadvars() []string {
	return []string{
		"description Saigon Cup 2023",
		"p1name Diego Umejuarez",
		"p1country jp",
		"p1score 1",
		"p1team Japan",
		"p2name Chokido",
		"p2country jp",
		"p2score 2",
		"p2team Japan2",
		"end",
	}
}
