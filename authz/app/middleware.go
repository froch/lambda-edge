package app

import (
	"log/slog"
	"net/http"
	"time"
)

// LogRequest logs the incoming HTTP requests
func LogRequest(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		clientIP := r.Header.Get("X-Forwarded-For")
		if clientIP == "" {
			clientIP = r.RemoteAddr
		}
		slog.Info("rcv",
			slog.String("method", r.Method),
			slog.String("uri", r.URL.RequestURI()),
			slog.String("client_ip", clientIP),
		)
		next.ServeHTTP(w, r)
	})
}

// LogResponse logs the HTTP responses
func LogResponse(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		lrw := &loggingResponseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(lrw, r)

		responseBody := lrw.body.String()
		slog.Info("rsp",
			slog.Int("status", lrw.statusCode),
			slog.String("body", responseBody),
			slog.String("duration", time.Since(start).String()),
		)
	})
}
