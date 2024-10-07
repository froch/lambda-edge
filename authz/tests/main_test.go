package tests

import (
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/froch/lambda-edge/authz/app"
)

// executeRequest is a helper function to test HTTP handlers
func executeRequest(method, url string, headers map[string]string) *httptest.ResponseRecorder {
	req, _ := http.NewRequest(method, url, nil)

	for key, value := range headers {
		req.Header.Set(key, value)
	}

	rr := httptest.NewRecorder()
	mux := http.NewServeMux()
	loggedMux := app.LogRequest(mux)

	mux.HandleFunc("/200", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{"message": "OK"}
		app.WriteOut(w, http.StatusOK, response)
	})
	mux.HandleFunc("/403", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{"message": "Nope"}
		app.WriteOut(w, http.StatusForbidden, response)
	})
	mux.HandleFunc("/headers", func(w http.ResponseWriter, r *http.Request) {
		for name, values := range r.Header {
			for _, value := range values {
				slog.Info("Header", "name", name, "value", value)
			}
		}
		app.WriteOut(w, http.StatusOK, http.StatusOK)
	})
	mux.HandleFunc("/authz", func(w http.ResponseWriter, r *http.Request) {
		wantAuthzHeader := os.Getenv("NIMBLE_AUTHZ_HEADER")
		gotAuthzHeader := r.Header.Get("Authorization")
		if gotAuthzHeader == "" {
			app.WriteOut(w, http.StatusForbidden, map[string]string{"message": "No authz header"})
			return
		}
		if gotAuthzHeader != wantAuthzHeader {
			app.WriteOut(w, http.StatusForbidden, map[string]string{"message": "Wrong authz header"})
			return
		}
		app.WriteOut(w, http.StatusOK, map[string]string{"message": "OK"})
	})

	loggedMux.ServeHTTP(rr, req)

	return rr
}

// TestWriteOut tests the WriteOut function
func TestWriteOut(t *testing.T) {
	tests := []struct {
		name          string
		status        int
		body          interface{}
		expectedBody  string
		expectedError string
	}{
		{
			name:         "StatusOK",
			status:       http.StatusOK,
			body:         map[string]string{"message": "OK"},
			expectedBody: `{"message":"OK"}`,
		},
		{
			name:          "InvalidBody",
			status:        http.StatusOK,
			body:          make(chan int),
			expectedError: "Failed to write response",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := httptest.NewRecorder()
			app.WriteOut(rr, tt.status, tt.body)

			if tt.expectedError != "" {
				if !strings.Contains(rr.Body.String(), tt.expectedError) {
					t.Errorf("Expected error not found: got %v want %v", rr.Body.String(), tt.expectedError)
				}
			} else if !strings.Contains(rr.Body.String(), tt.expectedBody) {
				t.Errorf("Expected body does not match result: got %v want %v", rr.Body.String(), tt.expectedBody)
			}
		})
	}
}

// TestHandlers tests the HTTP handlers
func TestHandlers(t *testing.T) {
	os.Setenv("NIMBLE_AUTHZ_HEADER", "correct-header")
	defer os.Unsetenv("NIMBLE_AUTHZ_HEADER")

	tests := []struct {
		name         string
		url          string
		method       string
		headers      map[string]string
		expectedCode int
		expectedBody string
	}{
		{
			name:         "200StatusOK",
			url:          "/200",
			method:       "GET",
			expectedCode: http.StatusOK,
			expectedBody: `{"message":"OK"}`,
		},
		{
			name:         "403StatusForbidden",
			url:          "/403",
			method:       "GET",
			expectedCode: http.StatusForbidden,
			expectedBody: `{"message":"Nope"}`,
		},
		{
			name:         "HeadersOK",
			url:          "/headers",
			method:       "GET",
			headers:      map[string]string{"X-Test-Header": "test"},
			expectedCode: http.StatusOK,
			expectedBody: "200", // because it encodes the status code
		},
		{
			name:         "AuthzNoHeader",
			url:          "/authz",
			method:       "GET",
			expectedCode: http.StatusForbidden,
			expectedBody: `{"message":"No authz header"}`,
		},
		{
			name:         "AuthzWrongHeader",
			url:          "/authz",
			method:       "GET",
			headers:      map[string]string{"Authorization": "wrong-header"},
			expectedCode: http.StatusForbidden,
			expectedBody: `{"message":"Wrong authz header"}`,
		},
		{
			name:         "AuthzCorrectHeader",
			url:          "/authz",
			method:       "GET",
			headers:      map[string]string{"Authorization": "correct-header"},
			expectedCode: http.StatusOK,
			expectedBody: `{"message":"OK"}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(tt.method, tt.url, tt.headers)
			if status := rr.Code; status != tt.expectedCode {
				t.Errorf("handler returned wrong status code: got %v want %v", status, tt.expectedCode)
			}
			if !strings.Contains(rr.Body.String(), tt.expectedBody) {
				t.Errorf("handler returned unexpected body: got %v want %v", rr.Body.String(), tt.expectedBody)
			}
		})
	}
}
