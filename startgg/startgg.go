package startgg

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"go.imnhan.com/gorts/players"
)

const STARTGG_URL = "https://api.start.gg/gql/alpha"

type GraphQL struct {
	Query     string   `json:"query"`
	Variables struct{} `json:"variables"`
}

func FetchPlayers(token string, tourneySlug string) ([]players.Player, error) {
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
		Query:     fmt.Sprintf(query, tourneySlug, 1),
		Variables: struct{}{},
	})
	if err != nil {
		panic(err)
	}

	req, err := http.NewRequest("POST", STARTGG_URL, bytes.NewBuffer(body))
	if err != nil {
		panic(err)
	}
	req.Header.Add("User-Agent", "GORTS/0.2")
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", "Bearer "+token)

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
