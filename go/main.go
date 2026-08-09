package main

import (
	"encoding/json"
	"net/http"

	spinhttp "github.com/spinframework/spin-go-sdk/v3/http"
)

type helloResponse struct {
	Component string `json:"component"`
	Message   string `json:"message"`
	Path      string `json:"path"`
}

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		path := r.Header.Get("spin-path-info")
		if path == "" {
			path = r.URL.Path
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(helloResponse{
			Component: "go",
			Message:   "Hello from Spin",
			Path:      path,
		})
	})
}

// main is required by the Go toolchain but is not executed by Spin.
func main() {}
