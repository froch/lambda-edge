package app

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux, wantAuthzHeader string) {
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

	mux.HandleFunc("/authz", func(w http.ResponseWriter, r *http.Request) {
		gotAuthzHeader := r.Header.Get("Authorization")
		if gotAuthzHeader == "" {
			response := map[string]string{"message": "No authz header"}
			slog.Error("No authz header")
			WriteOut(w, http.StatusForbidden, response)
			return
		}

		if gotAuthzHeader != wantAuthzHeader {
			response := map[string]string{"message": "Wrong authz header"}
			slog.Error("Wrong authz header")
			WriteOut(w, http.StatusForbidden, response)
			return
		}

		response := map[string]string{"message": "OK"}
		WriteOut(w, http.StatusOK, response)
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
