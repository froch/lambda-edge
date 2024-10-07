package app

import (
	"log/slog"
	"net/http"
	"time"
)

// LogRequest logs the incoming HTTP requests
func LogRequest(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		slog.Info("rc v",
			slog.String("method", r.Method),
			slog.String("uri", r.URL.RequestURI()),
			slog.String("remote", r.RemoteAddr),
		)
		next.ServeHTTP(w, r)
	})
}

// LogResponse logs the HTTP responses
func LogResponse(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Wrap the response writer to capture status
		lrw := &loggingResponseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(lrw, r)

		// Log response details after processing request
		slog.Info("Response sent",
			slog.Int("status", lrw.statusCode),
			slog.String("method", r.Method),
			slog.String("uri", r.URL.RequestURI()),
			slog.String("duration", time.Since(start).String()),
		)
	})
}
