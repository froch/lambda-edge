package app

import (
	"log/slog"
	"net/http"
)

// RegisterRoutes registers the routes
func (s *AuthzServer) RegisterRoutes(wantAuthzHeader string) {
	s.registerRoute("/200", http.StatusOK, "OK", nil)
	s.registerRoute("/403", http.StatusForbidden, "NOPE", nil)
	s.registerRoute("/headers", http.StatusOK, "OK", s.logHeaders)
	s.registerRoute("/authz", http.StatusOK, "OK", s.checkAuthzHeader(wantAuthzHeader))
}

// registerRoute registers a route
func (s *AuthzServer) registerRoute(path string, status int, message string, handlerFunc func(http.ResponseWriter, *http.Request) bool) {
	s.Mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		if handlerFunc != nil && !handlerFunc(w, r) {
			return
		}
		response := &BaseResponse{Message: message}
		WriteOut(w, status, response)
	})
}

// logHeaders logs the headers
func (s *AuthzServer) logHeaders(w http.ResponseWriter, r *http.Request) bool {
	for name, values := range r.Header {
		for _, value := range values {
			slog.Info("header", "name", name, "value", value)
		}
	}
	return true
}

// checkAuthzHeader checks the Authorization header
func (s *AuthzServer) checkAuthzHeader(wantAuthzHeader string) func(http.ResponseWriter, *http.Request) bool {
	return func(w http.ResponseWriter, r *http.Request) bool {
		gotAuthzHeader := r.Header.Get("Authorization")
		if errMsg := s.validateAuthzHeader(gotAuthzHeader, wantAuthzHeader); errMsg != "" {
			response := &BaseResponse{Message: errMsg}
			slog.Error("rcv", "error", errMsg)
			WriteOut(w, http.StatusForbidden, response)
			return false
		}
		return true
	}
}

// validateAuthzHeader validates the Authorization header
func (s *AuthzServer) validateAuthzHeader(gotAuthzHeader, wantAuthzHeader string) string {
	if gotAuthzHeader != wantAuthzHeader {
		return "Invalid authz header"
	}
	return ""
}
