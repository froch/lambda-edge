package app

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
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

		logLevel := slog.Info
		if lrw.statusCode >= 400 {
			logLevel = slog.Error
		}

		logLevel("rsp",
			slog.Int("status", lrw.statusCode),
			slog.String("body", fmtBody(lrw)),
			slog.String("duration", time.Since(start).String()),
		)
	})
}

// fmtBody formats the response body
func fmtBody(lrw *loggingResponseWriter) string {
	var formattedBody string
	if json.Valid(lrw.body.Bytes()) {
		var prettyJSON bytes.Buffer
		if err := json.Indent(&prettyJSON, lrw.body.Bytes(), "", ""); err == nil {
			formattedBody = prettyJSON.String()
		} else {
			formattedBody = lrw.body.String()
		}
	} else {
		formattedBody = lrw.body.String()
	}

	formattedBody = strings.ReplaceAll(formattedBody, "\n", "")
	formattedBody = strings.ReplaceAll(formattedBody, "\"", "")
	return formattedBody
}
