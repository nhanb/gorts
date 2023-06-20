package players

import (
	"encoding/csv"
	"log"
	"os"
)

type Player struct {
	Name    string
	Country string
	Team    string
}

// FromFile attempts to read players from csv file.
// If file does not exist, it returns an empty slice.
func FromFile(filepath string) []Player {
	players := make([]Player, 0)

	f, err := os.Open(filepath)
	if err != nil {
		return players
	}
	defer f.Close()

	reader := csv.NewReader(f)
	reader.FieldsPerRecord = 3
	records, err := reader.ReadAll()
	if err != nil {
		log.Fatalf("csv parse error for %s: %s", filepath, err)
	}

	for _, record := range records {
		p := Player{
			Name:    record[0],
			Country: record[1],
			Team:    record[2],
		}
		players = append(players, p)
	}

	return players
}
