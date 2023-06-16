package main

import (
	"bufio"
	_ "embed"
	"encoding/json"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
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

	// TODO: this should probably be refactored out
	state := initState()

	io.WriteString(stdin, "readvars\n")

	reqscanner := bufio.NewScanner(stdout)
	for reqscanner.Scan() {
		req := reqscanner.Text()
		println("=> " + req)
		switch req {
		case "readvars":
			for _, line := range serveReadvars(state) {
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

func serveReadvars(s State) []string {
	return []string{
		"description " + s.Description,
		"p1name " + s.P1name,
		"p1country " + s.P1country,
		"p1score " + strconv.Itoa(s.P1score),
		"p1team " + s.P1team,
		"p2name " + s.P2name,
		"p2country " + s.P2country,
		"p2score " + strconv.Itoa(s.P2score),
		"p2team " + s.P2team,
		"end",
	}
}

type State struct {
	Description string `json:"description"`
	P1name      string `json:"p1name"`
	P1country   string `json:"p1country"`
	P1score     int    `json:"p1score"`
	P1team      string `json:"p1team"`
	P2name      string `json:"p2name"`
	P2country   string `json:"p2country"`
	P2score     int    `json:"p2score"`
	P2team      string `json:"p2team"`
}

func initState() State {
	var state State
	file, err := os.Open(StateFile)
	if err == nil {
		bytes, err := ioutil.ReadAll(file)
		if err != nil {
			panic(err)
		}
		json.Unmarshal(bytes, &state)
	}
	return state
}
