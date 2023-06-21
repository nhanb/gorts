package netstring

import (
	"bufio"
	"strings"
	"testing"
)

func TestEncode(t *testing.T) {
	var tests = []struct {
		in  string
		out string
	}{
		{"hello world!", "12:hello world!,"},
		{"", "0:,"},
	}

	for _, tt := range tests {
		t.Run(tt.in, func(t *testing.T) {
			ans := Encode(tt.in)
			if ans != tt.out {
				t.Errorf("Encode(): got %s | want %s", ans, tt.out)
			}
		})
	}
}

func TestSplit(t *testing.T) {
	in := strings.NewReader("5:hello,6:world!,0:,")
	want := []string{"hello", "world!", ""}

	t.Run("Split", func(t *testing.T) {
		var results []string
		scanner := bufio.NewScanner(in)
		scanner.Split(SplitFunc)
		for scanner.Scan() {
			netstring := scanner.Text()
			results = append(results, netstring)
		}

		if len(results) != len(want) {
			t.Errorf("Split(): got %s | want %s", results, want)
		}
		for i, actual := range results {
			if actual != want[i] {
				t.Errorf("Split()[%d]: got %s | want %s", i, results, want)
			}
		}
	})
}
