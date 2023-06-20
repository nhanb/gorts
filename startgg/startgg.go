package startgg

import (
	"bufio"
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"go.imnhan.com/gorts/players"
)

const STARTGG_URL = "https://api.start.gg/gql/alpha"

type GraphQL struct {
	Query     string   `json:"query"`
	Variables struct{} `json:"variables"`
}

type Inputs struct {
	Token string
	Slug  string
}

func LoadInputs(filepath string) Inputs {
	var result Inputs
	file, err := os.Open(filepath)
	if err != nil {
		return result
	}
	defer file.Close()

	s := bufio.NewScanner(file)
	s.Scan()
	result.Token = s.Text()
	s.Scan()
	result.Slug = s.Text()
	return result
}

func (c *Inputs) Write(filepath string) {
	blob := []byte(fmt.Sprintf("%s\n%s\n", c.Token, c.Slug))
	err := ioutil.WriteFile(filepath, blob, 0644)
	if err != nil {
		panic(err)
	}
}

func FetchPlayers(i Inputs) ([]players.Player, error) {
	query := `
{
  tournament(slug: "%s") {
    participants(query: {page: %d, perPage: 500}) {
      nodes {
        entrants {
          event {
            slug
            name
          }
          team {
            name
          }
        }
        gamerTag
        prefix
        user {
          location {
            country
          }
        }
      }
    }
  }
}
`
	body, err := json.Marshal(GraphQL{
		Query:     fmt.Sprintf(query, i.Slug, 1),
		Variables: struct{}{},
	})
	if err != nil {
		panic(err)
	}

	req, err := http.NewRequest("POST", STARTGG_URL, bytes.NewBuffer(body))
	if err != nil {
		panic(err)
	}
	req.Header.Add("User-Agent", "GORTS/0.4")
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", "Bearer "+i.Token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch players: %w", err)
	}
	defer resp.Body.Close()

	respdata, err := ioutil.ReadAll(resp.Body)
	fmt.Println(">>>>", string(respdata))

	//var res map[string]interface{}
	//json.NewDecoder(resp.Body).Decode(&res)
	//fmt.Println(res["json"])
	return nil, nil
}
