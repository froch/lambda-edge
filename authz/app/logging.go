package app

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"sync"

	"github.com/rs/zerolog"
)

// Define ANSI color codes
const (
	ansiReset   = "\033[0m"
	ansiRed     = "\033[31m"
	ansiGreen   = "\033[32m"
	ansiYellow  = "\033[33m"
	ansiBlue    = "\033[34m"
	ansiMagenta = "\033[35m"
	ansiCyan    = "\033[36m"
	ansiWhite   = "\033[37m"
	ansiGray    = "\033[90m"
)

// LoggingConfig holds the configuration for the logger.
type LoggingConfig struct {
	Format string
	Level  string
}

// loggingResponseWriter captures status code and wraps ResponseWriter
type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
	body       *bytes.Buffer
}

// WriteHeader captures the status code
func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

// Write captures the response body
func (lrw *loggingResponseWriter) Write(b []byte) (int, error) {
	if lrw.body == nil {
		lrw.body = new(bytes.Buffer)
	}
	lrw.body.Write(b)
	return lrw.ResponseWriter.Write(b)
}

// zerologHandler implements slog.Handler using zerolog as backend
type zerologHandler struct {
	logger zerolog.Logger
	attrs  []slog.Attr
	groups []string
}

// Enabled reports whether the handler handles records at the given level.
func (h *zerologHandler) Enabled(ctx context.Context, level slog.Level) bool {
	zlLevel := slogLevelToZerologLevel(level)
	return zlLevel >= zerolog.GlobalLevel()
}

// Handle processes the log record.
func (h *zerologHandler) Handle(ctx context.Context, record slog.Record) error {
	zlLevel := slogLevelToZerologLevel(record.Level)
	event := h.logger.WithLevel(zlLevel).Timestamp()

	for _, attr := range h.attrs {
		event = event.Interface(attr.Key, attr.Value.Any())
	}

	if len(h.groups) > 0 {
		event = event.Strs("groups", h.groups)
	}

	sensitiveKeys := map[string]struct{}{
		"password": {},
		"secret":   {},
		// Add other sensitive keys here
	}

	record.Attrs(func(attr slog.Attr) bool {
		if _, isSensitive := sensitiveKeys[attr.Key]; isSensitive {
			return true
		}
		event = event.Interface(attr.Key, attr.Value.Any())
		return true
	})

	event.Msg(record.Message)
	return nil
}

// WithAttrs returns a new Handler with additional attributes.
func (h *zerologHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	newHandler := *h
	newHandler.attrs = append(newHandler.attrs, attrs...)
	return &newHandler
}

// WithGroup returns a new Handler with the given group appended.
func (h *zerologHandler) WithGroup(name string) slog.Handler {
	newHandler := *h
	newHandler.groups = append(newHandler.groups, name)
	return &newHandler
}

// slogLevelToZerologLevel maps slog.Level to zerolog.Level.
func slogLevelToZerologLevel(level slog.Level) zerolog.Level {
	switch {
	case level >= slog.LevelError:
		return zerolog.ErrorLevel
	case level >= slog.LevelWarn:
		return zerolog.WarnLevel
	case level >= slog.LevelInfo:
		return zerolog.InfoLevel
	case level >= slog.LevelDebug:
		return zerolog.DebugLevel
	default:
		return zerolog.TraceLevel
	}
}

// Initialize a mutex for thread safety
var initOnce sync.Once

// InitLogger initializes log/slog with a zerolog backend
func InitLogger(config LoggingConfig) {
	initOnce.Do(func() {
		zerolog.TimeFieldFormat = "2006-01-02 15:04:05"
		level, err := zerolog.ParseLevel(config.Level)
		if err != nil {
			level = zerolog.InfoLevel
		}
		zerolog.SetGlobalLevel(level)

		var output io.Writer = os.Stderr
		if config.Format == "text" {
			output = zerolog.ConsoleWriter{
				Out:        os.Stderr,
				TimeFormat: zerolog.TimeFieldFormat,
				FormatLevel: func(i interface{}) string {
					levelStr := strings.ToUpper(fmt.Sprintf("%-6s", i))
					var color string
					switch levelStr {
					case "DEBUG ":
						color = ansiMagenta
					case "INFO  ":
						color = ansiGreen
					case "WARN  ":
						color = ansiYellow
					case "ERROR ":
						color = ansiRed
					default:
						color = ansiWhite
					}
					return color + levelStr + ansiReset
				},
				FormatTimestamp: func(i interface{}) string {
					return ansiGray + fmt.Sprintf("%s", i) + ansiReset
				},
				FormatMessage: func(i interface{}) string {
					return fmt.Sprintf("%s", i)
				},
				FormatFieldName: func(i interface{}) string {
					return ansiCyan + fmt.Sprintf("%s=", i) + ansiReset
				},
				FormatFieldValue: func(i interface{}) string {
					return ansiWhite + fmt.Sprintf("%v", i) + ansiReset
				},
			}
		}

		zl := zerolog.New(output).With().Timestamp().Logger()
		handler := &zerologHandler{logger: zl}
		logger := slog.New(handler)

		slog.SetDefault(logger)
	})
}
