package tests

import (
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
	wantAuthzHeader := os.Getenv("AUTHZ_HEADER")

	server := app.NewAuthzServer("localhost", 8080, mux, mux)
	server.RegisterRoutes(wantAuthzHeader)

	loggedHandler := app.LogRequest(app.LogResponse(server.Mux))
	loggedHandler.ServeHTTP(rr, req)

	return rr
}

// TestWriteOut tests the WriteOut function
func TestWriteOut(t *testing.T) {
	tests := []struct {
		name          string
		status        int
		body          *app.BaseResponse
		expectedBody  *app.BaseResponse
		expectedError string
	}{
		{
			name:         "StatusOK",
			status:       http.StatusOK,
			body:         &app.BaseResponse{Message: "OK"},
			expectedBody: &app.BaseResponse{Message: "OK"},
		},
		{
			name:          "InvalidBody",
			status:        http.StatusOK,
			body:          nil,
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
			} else if !strings.Contains(rr.Body.String(), tt.expectedBody.Message) {
				t.Errorf("Expected body does not match result: got %v want %v", rr.Body.String(), tt.expectedBody)
			}
		})
	}
}

// TestHandlers tests the HTTP handlers
// TestHandlers tests the HTTP handlers
func TestHandlers(t *testing.T) {
	os.Setenv("AUTHZ_HEADER", "correct-header")
	defer os.Unsetenv("AUTHZ_HEADER")

	tests := []struct {
		name         string
		url          string
		method       string
		headers      map[string]string
		expectedCode int
		expectedBody *app.BaseResponse
	}{
		{
			name:         "200StatusOK",
			url:          "/200",
			method:       "GET",
			expectedCode: http.StatusOK,
			expectedBody: &app.BaseResponse{Message: "OK"},
		},
		{
			name:         "403StatusForbidden",
			url:          "/403",
			method:       "GET",
			expectedCode: http.StatusForbidden,
			expectedBody: &app.BaseResponse{Message: "NOPE"},
		},
		{
			name:         "HeadersOK",
			url:          "/headers",
			method:       "GET",
			headers:      map[string]string{"X-Test-Header": "test"},
			expectedCode: http.StatusOK,
			expectedBody: &app.BaseResponse{Message: "OK"},
		},
		{
			name:         "AuthzNoHeader",
			url:          "/authz",
			method:       "GET",
			expectedCode: http.StatusForbidden,
			expectedBody: &app.BaseResponse{Message: "no Authz header"},
		},
		{
			name:         "AuthzWrongHeader",
			url:          "/authz",
			method:       "GET",
			headers:      map[string]string{"Authorization": "wrong-header"},
			expectedCode: http.StatusForbidden,
			expectedBody: &app.BaseResponse{Message: "wrong Authz header"},
		},
		{
			name:         "AuthzCorrectHeader",
			url:          "/authz",
			method:       "GET",
			headers:      map[string]string{"Authorization": "correct-header"},
			expectedCode: http.StatusOK,
			expectedBody: &app.BaseResponse{Message: "OK"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rr := executeRequest(tt.method, tt.url, tt.headers)
			if status := rr.Code; status != tt.expectedCode {
				t.Errorf("handler returned wrong status code: got %v want %v", status, tt.expectedCode)
			}
			if !strings.Contains(rr.Body.String(), tt.expectedBody.Message) {
				t.Errorf("handler returned unexpected body: got %v want %v", rr.Body.String(), tt.expectedBody.Message)
			}
		})
	}
}
