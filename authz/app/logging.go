package app

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/fatih/color"
)

// loggingResponseWriter captures status code and wraps ResponseWriter
type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

// WriteHeader to capture status code
func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

// InitLogger initializes the custom slog logger with color support
func InitLogger() {
	handler := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		AddSource: true,
		Level:     slog.LevelInfo,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			// Apply color to log levels
			switch a.Key {
			case slog.LevelKey:
				switch a.Value.String() {
				case "INFO":
					a.Value = slog.StringValue(color.New(color.FgGreen).Sprint("INFO"))
				case "ERROR":
					a.Value = slog.StringValue(color.New(color.FgRed).Sprint("ERROR"))
				}
			case slog.MessageKey:
				// Color keys differently for INFO and ERROR
				if a.Value.String() == "INFO" {
					a.Value = slog.StringValue(color.New(color.FgCyan).Sprint(a.Value.String()))
				} else if a.Value.String() == "ERROR" {
					a.Value = slog.StringValue(color.New(color.FgRed).Sprint(a.Value.String()))
				}
			}
			return a
		},
	})

	logger := slog.New(handler)

	// Set logger as the default
	slog.SetDefault(logger)
}
