package main

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/froch/lambda-edge/authz/app"
)

const (
	ServerBind = "0.0.0.0"
	ServerPort = 8080
)

func main() {
	app.InitLogger(app.LoggingConfig{
		Format: "text",
		Level:  "info",
	})

	mux := http.NewServeMux()
	loggedHandler := app.LogRequest(app.LogResponse(mux))

	wantAuthzHeader := os.Getenv("AUTHZ_HEADER")
	if wantAuthzHeader == "" {
		slog.Error("rcv", slog.String("error", "missing AUTHZ_HEADER"))
	}

	server := app.NewAuthzServer(
		ServerBind,
		ServerPort,
		loggedHandler,
		mux,
	)
	server.RegisterRoutes(wantAuthzHeader)

	slog.Info("server started",
		slog.String("bind", ServerBind),
		slog.Int("port", ServerPort),
	)

	if err := server.ListenAndServe(); err != nil {
		slog.Error("server failed", "error", err)
	}
}
