package app

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
)

type BaseResponse struct {
	Message string `json:"message"`
}

func RegisterRoutes(mux *http.ServeMux, wantAuthzHeader string) {
	mux.HandleFunc("/200", func(w http.ResponseWriter, r *http.Request) {
		response := &BaseResponse{Message: "OK"}
		WriteOut(w, http.StatusOK, response)
	})

	mux.HandleFunc("/403", func(w http.ResponseWriter, r *http.Request) {
		response := &BaseResponse{Message: "NOPE"}
		WriteOut(w, http.StatusForbidden, response)
	})

	mux.HandleFunc("/headers", func(w http.ResponseWriter, r *http.Request) {
		for name, values := range r.Header {
			for _, value := range values {
				slog.Info("header", "name", name, "value", value)
			}
		}
		response := &BaseResponse{Message: "OK"}
		WriteOut(w, http.StatusOK, response)
	})

	mux.HandleFunc("/authz", func(w http.ResponseWriter, r *http.Request) {
		gotAuthzHeader := r.Header.Get("Authorization")
		if gotAuthzHeader == "" {
			str := "no Authz header"
			response := &BaseResponse{Message: str}
			slog.Error(str)
			WriteOut(w, http.StatusForbidden, response)
			return
		}

		if gotAuthzHeader != wantAuthzHeader {
			str := "wrong Authz header"
			response := &BaseResponse{Message: str}
			slog.Error(str)
			WriteOut(w, http.StatusForbidden, response)
			return
		}

		response := &BaseResponse{Message: "OK"}
		WriteOut(w, http.StatusOK, response)
	})
}

func WriteOut(w http.ResponseWriter, status int, body *BaseResponse) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	var buffer bytes.Buffer
	encoder := json.NewEncoder(&buffer)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(body); err != nil {
		str := "failed to encode response"
		slog.Error(str, "error", err)
		http.Error(w, str, http.StatusInternalServerError)
		return
	}

	_, err := w.Write(buffer.Bytes())
	if err != nil {
		str := "failed to write response"
		slog.Error(str, "error", err)
		http.Error(w, str, http.StatusInternalServerError)
		return
	}
}
