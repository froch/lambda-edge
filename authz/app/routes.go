package app

import (
	"log/slog"
	"net/http"
)

func (s *AuthzServer) RegisterRoutes(wantAuthzHeader string) {
	s.register200()
	s.register403()
	s.registerHeaders()
	s.registerAuthz(wantAuthzHeader)
}

func (s *AuthzServer) register200() {
	s.Mux.HandleFunc("/200", func(w http.ResponseWriter, r *http.Request) {
		response := &BaseResponse{Message: "OK"}
		WriteOut(w, http.StatusOK, response)
	})
}

func (s *AuthzServer) register403() {
	s.Mux.HandleFunc("/403", func(w http.ResponseWriter, r *http.Request) {
		response := &BaseResponse{Message: "NOPE"}
		WriteOut(w, http.StatusForbidden, response)
	})
}

func (s *AuthzServer) registerHeaders() {
	s.Mux.HandleFunc("/headers", func(w http.ResponseWriter, r *http.Request) {
		for name, values := range r.Header {
			for _, value := range values {
				slog.Info("header", "name", name, "value", value)
			}
		}
		response := &BaseResponse{Message: "OK"}
		WriteOut(w, http.StatusOK, response)
	})
}

func (s *AuthzServer) registerAuthz(wantAuthzHeader string) {
	s.Mux.HandleFunc("/authz", func(w http.ResponseWriter, r *http.Request) {
		gotAuthzHeader := r.Header.Get("Authorization")
		if gotAuthzHeader == "" {
			str := "no Authz header"
			response := &BaseResponse{Message: str}
			slog.Error("rcv", "error", str)
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
