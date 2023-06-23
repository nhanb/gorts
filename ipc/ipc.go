package ipc

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"strconv"
	"strings"
)

type Request struct {
	Method string
	Args   []string
}

func debug(prefix string, msg string) {
	out := prefix + " " + msg
	if len(out) > 35 {
		out = out[:35] + "[...]"
	}
	fmt.Println(out)
}

func IncomingRequests(r io.Reader) chan Request {
	scanner := bufio.NewScanner(r)
	ch := make(chan Request)
	next := func() string {
		scanner.Scan()
		v := scanner.Text()
		debug("-->", v)
		return v
	}

	go func() {
		for scanner.Scan() {
			line := scanner.Text()
			debug("-->", line)
			request := strings.SplitN(line, " ", 2)
			method := request[0]
			numArgs, err := strconv.Atoi(request[1])
			if err != nil {
				panic(err)
			}
			args := make([]string, numArgs)
			for i := 0; i < numArgs; i++ {
				args[i] = next()
			}

			ch <- Request{Method: method, Args: args}
		}
		if err := scanner.Err(); err != nil {
			log.Fatal(err)
		}

		close(ch)
	}()

	return ch
}

func Respond(w io.Writer, values []string) {
	numValues := strconv.Itoa(len(values))
	debug("<--", numValues)
	fmt.Fprintln(w, numValues)
	for i, val := range values {
		// Only print debug message for the first 10 items
		if i <= 10 {
			var msg string
			if i < 10 {
				msg = val
			} else if i == 10 {
				msg = "[...]"
			}
			debug("<--", msg)
		}

		fmt.Fprintln(w, val)
	}
}
