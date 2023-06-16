package main

import (
	"bufio"
	_ "embed"
	"io"
	"log"
	"net/http"
	"os/exec"
	"sync"
)

const WebPort = "1337"
const WebDir = "web"
const StateFile = WebDir + "/state.json"

//go:embed tcl/main.tcl
var mainTcl string

func main() {
	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		connectTclProc()
	}()

	// No need to wait on the http server,
	// just let it die when the GUI is closed.
	go func() {
		println("Serving scoreboard at http://localhost:" + WebPort)
		fs := http.FileServer(http.Dir(WebDir))
		http.Handle("/", fs)
		err := http.ListenAndServe("127.0.0.1:"+WebPort, nil)
		if err != nil {
			log.Fatal(err)
		}
	}()

	wg.Wait()
}

func connectTclProc() {
	cmd := exec.Command("tclsh")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		panic(err)
	}

	stdin, err := cmd.StdinPipe()
	if err != nil {
		panic(err)
	}

	err = cmd.Start()
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
