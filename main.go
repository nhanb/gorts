package main

import (
	"bufio"
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"

	"go.imnhan.com/gorts/ipc"
	"go.imnhan.com/gorts/players"
	"go.imnhan.com/gorts/startgg"
)

const WebPort = "1337"
const WebDir = "web"
const ScoreboardFile = WebDir + "/state.json"
const PlayersFile = "players.csv"
const StartggFile = "creds-startgg"

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

	tclPathPtr := flag.String("tcl", DefaultTclPath, "Path to tclsh executable")
	flag.Parse()

	startGUI(*tclPathPtr)
}

func startGUI(tclPath string) {
	cmd := exec.Command(tclPath, "-encoding", "utf-8")
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

	fmt.Fprintln(stdin, `source -encoding "utf-8" tcl/main.tcl`)
	println("Loaded main tcl script.")

	allplayers := players.FromFile(PlayersFile)
	scoreboard := initScoreboard()
	startggInputs := startgg.LoadInputs(StartggFile)

	fmt.Fprintln(stdin, "initialize")

	respond := func(values ...string) {
		ipc.Respond(stdin, values)
	}

	for req := range ipc.IncomingRequests(stdout) {
		switch req.Method {

		case "forcefocus":
			err := forceFocus(req.Args[0])
			if err != nil {
				fmt.Printf("forcefocus: %s\n", err)
			}
			respond("ok")

		case "geticon":
			respond(base64.StdEncoding.EncodeToString([]byte(gortsPngIcon)))

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
			scoreboard.Description = req.Args[0]
			scoreboard.Subtitle = req.Args[1]
			scoreboard.P1name = req.Args[2]
			scoreboard.P1country = req.Args[3]
			scoreboard.P1score, _ = strconv.Atoi(req.Args[4])
			scoreboard.P1team = req.Args[5]
			scoreboard.P2name = req.Args[6]
			scoreboard.P2country = req.Args[7]
			scoreboard.P2score, _ = strconv.Atoi(req.Args[8])
			scoreboard.P2team = req.Args[9]
			scoreboard.Write()
			respond()

		case "searchplayers":
			query := req.Args[0]
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

		case "fetchplayers":
			startggInputs.Token = req.Args[0]
			startggInputs.Slug = req.Args[1]
			ps, err := startgg.FetchPlayers(startggInputs)
			fmt.Fprintln(stdin, "fetchplayers__resp")
			if err != nil {
				respond("err", fmt.Sprintf("Error: %s", err))
				break
			}
			allplayers = ps
			// TODO: show write errors to user instead of ignoring
			startggInputs.Write(StartggFile)
			players.Write(PlayersFile, allplayers)
			respond("ok", fmt.Sprintf("Successfully fetched %d players.", len(allplayers)))

		case "clearstartgg":
			startggInputs = startgg.Inputs{}
			startggInputs.Write(StartggFile)

		case "getplayercountry":
			playerName := req.Args[0]
			var country string
			for _, p := range allplayers {
				if p.Name == playerName {
					country = p.Country
					break
				}
			}
			respond(country)
		}
	}

	println("Tcl process terminated.")
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
