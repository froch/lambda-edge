package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	loggedMux := LogRequest(mux)

	mux.HandleFunc("/200", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{"message": "OK"}
		WriteOut(w, http.StatusOK, response)
	})

	mux.HandleFunc("/403", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{"message": "OK"}
		WriteOut(w, http.StatusForbidden, response)
	})

	server := &http.Server{
		Addr:    "0.0.0.0:8080",
		Handler: loggedMux,
	}

	slog.Info("Starting server on :8080")
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
