package app

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
)

// AuthzServer is the HTTP server
type AuthzServer struct {
	*http.Server
	Addr    string
	Handler http.Handler
	Mux     *http.ServeMux
}

// NewAuthzServer creates a new HTTP server
func NewAuthzServer(bind string, port int, handler http.Handler, mux *http.ServeMux) *AuthzServer {
	return &AuthzServer{
		Server: &http.Server{
			Addr:    fmt.Sprintf("%s:%d", bind, port),
			Handler: handler,
		},
		Mux: mux,
	}
}

// WriteOut writes the response to the client
func WriteOut(w http.ResponseWriter, status int, body *BaseResponse) {
	if body == nil {
		str := "Failed to write response: body is nil"
		slog.Error(str)
		http.Error(w, str, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	var buffer bytes.Buffer
	encoder := json.NewEncoder(&buffer)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(body); err != nil {
		str := "Failed to encode response"
		slog.Error(str, "error", err)
		http.Error(w, str, http.StatusInternalServerError)
		return
	}

	_, err := w.Write(buffer.Bytes())
	if err != nil {
		str := "Failed to write response"
		slog.Error(str, "error", err)
		http.Error(w, str, http.StatusInternalServerError)
		return
	}
}
