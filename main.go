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

	io.WriteString(stdin, "readstate\n")

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		req := scanner.Text()
		println("=> " + req)
		switch req {
		case "readstate":
			for _, line := range []string{
				"description " + state.Description,
				"p1name " + state.P1name,
				"p1country " + state.P1country,
				"p1score " + strconv.Itoa(state.P1score),
				"p1team " + state.P1team,
				"p2name " + state.P2name,
				"p2country " + state.P2country,
				"p2score " + strconv.Itoa(state.P2score),
				"p2team " + state.P2team,
				"end",
			} {
				println("<= " + line)
				io.WriteString(stdin, line+"\n")
			}
		case "applystate":
			next := func() string {
				scanner.Scan()
				v := scanner.Text()
				println("=>", v)
				return v
			}
			// TODO: there must be more... civilized way.
			state.Description = next()
			state.P1name = next()
			state.P1country = next()
			state.P1score, _ = strconv.Atoi(next())
			state.P1team = next()
			state.P2name = next()
			state.P2country = next()
			state.P2score, _ = strconv.Atoi(next())
			state.P2team = next()
			state.Write()

		default:
			println("Skipping bogus command: " + req)
		}
	}

	println("Tcl process terminated.")

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
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
		defer file.Close()
		bytes, err := ioutil.ReadAll(file)
		if err != nil {
			panic(err)
		}
		json.Unmarshal(bytes, &state)
	}
	return state
}

func (s *State) Write() {
	blob, err := json.MarshalIndent(s, "", "    ")
	if err != nil {
		panic(err)
	}
	err = ioutil.WriteFile(StateFile, blob, 0644)
	if err != nil {
		panic(err)
	}
}
