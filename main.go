package main

import (
	"bufio"
	_ "embed"
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
	"time"

	"go.imnhan.com/gorts/netstring"
	"go.imnhan.com/gorts/players"
	"go.imnhan.com/gorts/startgg"
)

const WebPort = "1337"
const WebDir = "web"
const ScoreboardFile = WebDir + "/state.json"
const PlayersFile = "players.csv"
const StartggFile = "creds-start.gg"

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
			fmt.Printf("XXX %s\n", errtext)
		}
	}()

	fmt.Fprintln(stdin, mainTcl)
	println("Loaded main tcl script.")

	allplayers := players.FromFile(PlayersFile)
	scoreboard := initScoreboard()
	startggInputs := startgg.LoadInputs(StartggFile)

	fmt.Fprintln(stdin, "initialize")

	scanner := bufio.NewScanner(stdout)
	scanner.Split(netstring.SplitFunc)

	next := func() string {
		scanner.Scan()
		v := scanner.Text()
		println("-->", v)
		return v
	}

	respondOld := func(s string) {
		debug := "<-- " + s
		if len(debug) > 35 {
			debug = debug[:35] + "[...]"
		}
		println(debug)
		io.WriteString(stdin, netstring.Encode(s))
	}

	respond := func(ss ...string) {
		debug := fmt.Sprintf("<-- %v", ss)
		if len(debug) > 35 {
			debug = debug[:35] + "[...]"
		}
		println(debug)
		payload := netstring.EncodeN(ss...)
		io.WriteString(stdin, payload)
	}

	for scanner.Scan() {
		req := netstring.DecodeMultiple(scanner.Text())
		fmt.Printf("--> %v\n", req)
		switch req[0] {
		case "geticon":
			respond(string(gortsPngIcon))

		case "getstartgg":
			respond(startggInputs.Token, startggInputs.Slug)

		case "getwebport":
			respond(WebPort)

		case "getcountrycodes":
			respond(startgg.CountryCodes...)

		case "getscoreboard":
			// TODO: there must be a more... civilized way.
			respond(
				scoreboard.Description,
				scoreboard.Subtitle,
				scoreboard.P1name,
				scoreboard.P1country,
				strconv.Itoa(scoreboard.P1score),
				scoreboard.P1team,
				scoreboard.P2name,
				scoreboard.P2country,
				strconv.Itoa(scoreboard.P2score),
				scoreboard.P2team,
			)

		case "applyscoreboard":
			sb := req[1:]
			scoreboard.Description = sb[0]
			scoreboard.Subtitle = sb[1]
			scoreboard.P1name = sb[2]
			scoreboard.P1country = sb[3]
			scoreboard.P1score, _ = strconv.Atoi(sb[4])
			scoreboard.P1team = sb[5]
			scoreboard.P2name = sb[6]
			scoreboard.P2country = sb[7]
			scoreboard.P2score, _ = strconv.Atoi(sb[8])
			scoreboard.P2team = sb[9]
			scoreboard.Write()
			respond("ok")

		case "searchplayers":
			query := req[1]
			var names []string

			if query == "" {
				for _, p := range allplayers {
					names = append(names, p.Name)
				}
				respond(names...)
				break
			}

			for _, p := range allplayers {
				if p.MatchesName(query) {
					names = append(names, p.Name)
				}
			}
			respond(names...)

		case "fetchplayers": // FIXME
			startggInputs.Token = next()
			startggInputs.Slug = next()
			time.Sleep(3 * time.Second)
			respondOld("fetchplayers__resp")
			respondOld("All done.")
			startggInputs.Write(StartggFile)
		}
	}

	println("Tcl process terminated.")

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}

type Scoreboard struct {
	Description string `json:"description"`
	Subtitle    string `json:"subtitle"`
	P1name      string `json:"p1name"`
	P1country   string `json:"p1country"`
	P1score     int    `json:"p1score"`
	P1team      string `json:"p1team"`
	P2name      string `json:"p2name"`
	P2country   string `json:"p2country"`
	P2score     int    `json:"p2score"`
	P2team      string `json:"p2team"`
}

func initScoreboard() Scoreboard {
	var scoreboard Scoreboard
	file, err := os.Open(ScoreboardFile)
	if err == nil {
		defer file.Close()
		bytes, err := ioutil.ReadAll(file)
		if err != nil {
			panic(err)
		}
		json.Unmarshal(bytes, &scoreboard)
	}
	return scoreboard
}

func (s *Scoreboard) Write() {
	blob, err := json.MarshalIndent(s, "", "    ")
	if err != nil {
		panic(err)
	}
	err = ioutil.WriteFile(ScoreboardFile, blob, 0644)
	if err != nil {
		panic(err)
	}
}
