package app

import (
	"crypto/sha256"
	"fmt"
	"log/slog"
	"net/http"
)

// RegisterRoutes registers the routes
func (s *AuthzServer) RegisterRoutes(wantAuthzHeader string) {
	s.registerRoute("/200", http.StatusOK, "OK", nil)
	s.registerRoute("/403", http.StatusForbidden, "NOPE", nil)
	s.registerRoute("/headers", http.StatusOK, "OK", s.logHeaders)
	s.registerRoute("/authz", http.StatusForbidden, "NOPE", s.checkAuthzHeader(wantAuthzHeader))
}

// registerRoute registers a route
func (s *AuthzServer) registerRoute(
	path string,
	defaultStatus int,
	defaultMessage string,
	handlerFunc func(http.ResponseWriter, *http.Request) bool,
) {
	s.Mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		if handlerFunc != nil && handlerFunc(w, r) {
			response := &BaseResponse{Message: "OK"}
			WriteOut(w, http.StatusOK, response)
			return
		}
		response := &BaseResponse{Message: defaultMessage}
		WriteOut(w, defaultStatus, response)
	})
}

// logHeaders logs the client headers to server console
func (s *AuthzServer) logHeaders(w http.ResponseWriter, r *http.Request) bool {
	for name, values := range r.Header {
		for _, value := range values {
			slog.Info("header", "name", name, "value", value)
		}
	}
	return true
}

// checkAuthzHeader checks for a valid Authorization header
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

// validateAuthzHeader ensures the Authorization header is valid
func (s *AuthzServer) validateAuthzHeader(gotAuthzHeader, wantAuthzHeader string) string {
	if gotAuthzHeader == "" {
		slog.Error("validate", "gotHeader", gotAuthzHeader)
		return "No Authorization header"
	}

	gotHash := sha256.Sum256([]byte(gotAuthzHeader))
	wantHash := sha256.Sum256([]byte(wantAuthzHeader))

	if gotHash != wantHash {
		xorHash := make([]byte, len(gotHash))
		for i := 0; i < len(gotHash); i++ {
			xorHash[i] = gotHash[i] ^ wantHash[i]
		}
		diff := fmt.Sprintf("%x", xorHash)
		slog.Error("validate", "gotHeader", gotAuthzHeader, "wantHeader", wantAuthzHeader, "hashDiff", diff)
		return "Invalid Authorization header"
	}

	return ""
}
