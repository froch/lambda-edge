package app

import (
	"bytes"
	"log/slog"
	"net/http"
	"os"

	"github.com/lmittmann/tint"
	"github.com/mattn/go-isatty"
)

// ANSI color codes
const (
	ansiReset       = "\033[0m"
	ansiFaint       = "\033[2m"
	ansiResetFaint  = "\033[22m"
	ansiBrightGreen = "\033[92m"
	ansiBrightRed   = "\033[91m"
	ansiBrightCyan  = "\033[96m"
	ansiWhite       = "\033[97m"
)

// loggingResponseWriter captures status code and wraps ResponseWriter
type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
	body       *bytes.Buffer
}

// WriteHeader to capture status code
func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

// Write to capture the response body
func (lrw *loggingResponseWriter) Write(b []byte) (int, error) {
	if lrw.body == nil {
		lrw.body = new(bytes.Buffer)
	}
	lrw.body.Write(b)
	return lrw.ResponseWriter.Write(b)
}

// InitLogger initializes the custom slog logger with color support
func InitLogger() {
	w := os.Stderr
	logger := slog.New(
		tint.NewHandler(w, &tint.Options{
			NoColor: !isatty.IsTerminal(w.Fd()),
			ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
				switch a.Key {
				case slog.TimeKey:
					{
						t := a.Value.Time()
						a.Value = slog.StringValue(ansiFaint + t.Format("2006-01-02 15:04:05") + ansiResetFaint)
					}
				case slog.LevelKey:
					{
						switch a.Value.String() {
						case "INFO":
							a.Value = slog.StringValue(ansiBrightGreen + "INFO" + ansiReset)
						case "ERROR":
							a.Value = slog.StringValue(ansiBrightRed + "ERROR" + ansiReset)
						}
					}
				case slog.MessageKey:
					{
						a.Value = slog.StringValue(ansiBrightCyan + a.Value.String() + ansiReset)
					}
				default:
					{
					}
				}
				return a
			},
		}),
	)
	slog.SetDefault(logger)
}
