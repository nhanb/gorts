package main

import (
	"bufio"
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strconv"
)

const WebPort = "1337"
const WebDir = "web"
const StateFile = WebDir + "/state.json"

//go:embed tcl/main.tcl
var mainTcl string

//go:embed gorts.png
var gortsPngIcon []byte

func main() {
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

	startGUI()
}

func startGUI() {
	tclPath := "tclsh"
	if runtime.GOOS == "windows" {
		tclPath = "./tclkit.exe"
	}

	cmd := exec.Command(tclPath)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		panic(err)
	}

	stdin, err := cmd.StdinPipe()
	if err != nil {
		panic(err)
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		panic(err)
	}

	err = cmd.Start()
	if err != nil {
		panic(err)
	}

	go func() {
		errscanner := bufio.NewScanner(stderr)
		for errscanner.Scan() {
			errtext := errscanner.Text()
			fmt.Printf("~~> %s\n", errtext)
		}
	}()

	fmt.Fprintln(stdin, mainTcl)
	println("Loaded main tcl script.")

	state := initState()

	b64icon := base64.StdEncoding.EncodeToString(gortsPngIcon)

	fmt.Fprintf(stdin, "initialize %s %s\n", b64icon, WebPort)

	scanner := bufio.NewScanner(stdout)

	next := func() string {
		scanner.Scan()
		v := scanner.Text()
		println("==>", v)
		return v
	}

	respond := func(s string) {
		println("<==", s)
		io.WriteString(stdin, s+"\n")
	}

	for scanner.Scan() {
		req := scanner.Text()
		println("==> " + req)
		switch req {
		case "readstate":
			// TODO: there must be a more... civilized way.
			respond(state.Description)
			respond(state.P1name)
			respond(state.P1country)
			respond(strconv.Itoa(state.P1score))
			respond(state.P1team)
			respond(state.P2name)
			respond(state.P2country)
			respond(strconv.Itoa(state.P2score))
			respond(state.P2team)
		case "applystate":
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
