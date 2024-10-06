package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
)

const (
	ServerBind = "0.0.0.0"
	ServerPort = 8080
)

func main() {
	mux := http.NewServeMux()
	loggedMux := LogRequest(mux)

	mux.HandleFunc("/200", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{"message": "OK"}
		WriteOut(w, http.StatusOK, response)
	})
	mux.HandleFunc("/403", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{"message": "Nope"}
		WriteOut(w, http.StatusForbidden, response)
	})
	mux.HandleFunc("/headers", func(w http.ResponseWriter, r *http.Request) {
		for name, values := range r.Header {
			for _, value := range values {
				slog.Info("Header", "name", name, "value", value)
			}
		}
		WriteOut(w, http.StatusOK, http.StatusOK)
	})

	server := &http.Server{
		Addr:    fmt.Sprintf("%s:%d", ServerBind, ServerPort),
		Handler: loggedMux,
	}

	slog.Info(fmt.Sprintf("Starting server on %s:%d", ServerBind, ServerPort))
	if err := server.ListenAndServe(); err != nil {
		slog.Error("Server failed", "error", err)
	}
}

func LogRequest(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		slog.Info(r.Method,
			slog.String("uri", r.URL.RequestURI()),
			slog.String("remote", r.RemoteAddr),
		)
		next.ServeHTTP(w, r)
	})
}

func WriteOut(w http.ResponseWriter, status int, body interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		slog.Error("Failed to write response", "error", err)
		http.Error(w, "Failed to write response", http.StatusInternalServerError)
	}
}
