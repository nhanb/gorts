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
	"strings"
	"time"

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

	next := func() string {
		scanner.Scan()
		v := scanner.Text()
		println("-->", v)
		return v
	}

	respond := func(s string) {
		debug := "<-- " + s
		if len(debug) > 35 {
			debug = debug[:35] + "[...]"
		}
		println(debug)
		io.WriteString(stdin, s+"\n")
	}

	for scanner.Scan() {
		req := scanner.Text()
		println("--> " + req)
		switch req {
		case "readscoreboard":
			// TODO: there must be a more... civilized way.
			respond(scoreboard.Description)
			respond(scoreboard.Subtitle)
			respond(scoreboard.P1name)
			respond(scoreboard.P1country)
			respond(strconv.Itoa(scoreboard.P1score))
			respond(scoreboard.P1team)
			respond(scoreboard.P2name)
			respond(scoreboard.P2country)
			respond(strconv.Itoa(scoreboard.P2score))
			respond(scoreboard.P2team)

		case "applyscoreboard":
			scoreboard.Description = next()
			scoreboard.Subtitle = next()
			scoreboard.P1name = next()
			scoreboard.P1country = next()
			scoreboard.P1score, _ = strconv.Atoi(next())
			scoreboard.P1team = next()
			scoreboard.P2name = next()
			scoreboard.P2country = next()
			scoreboard.P2score, _ = strconv.Atoi(next())
			scoreboard.P2team = next()
			scoreboard.Write()

		case "readplayernames":
			for _, player := range allplayers {
				respond(player.Name)
			}
			respond("end")

		case "searchplayers":
			query := strings.TrimSpace(next())

			if query == "" {
				for _, p := range allplayers {
					respond(p.Name)
				}
				respond("end")
				break
			}

			for _, p := range allplayers {
				if p.MatchesName(query) {
					respond(p.Name)
				}
			}
			respond("end")

		case "fetchplayers":
			startggInputs.Token = next()
			startggInputs.Slug = next()
			time.Sleep(3 * time.Second)
			respond("fetchplayers__resp")
			respond("All done.")
			startggInputs.Write(StartggFile)

		case "readwebport":
			respond(WebPort)

		case "geticon":
			b64icon := base64.StdEncoding.EncodeToString(gortsPngIcon)
			respond(b64icon)

		case "getcountrycodes":
			respond(strings.Join(startgg.CountryCodes, " "))

		case "readstartgg":
			respond(startggInputs.Token)
			respond(startggInputs.Slug)
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
