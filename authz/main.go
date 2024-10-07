package main

import (
	"fmt"
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
	app.InitLogger()

	mux := http.NewServeMux()
	loggedMux := app.LogRequest(app.LogResponse(mux))

	wantAuthzHeader := os.Getenv("AUTHZ_HEADER")
	if wantAuthzHeader == "" {
		slog.Error("env unset", slog.String("key", "AUTHZ_HEADER"))
	}

	app.RegisterRoutes(mux, wantAuthzHeader)

	server := &http.Server{
		Addr:    fmt.Sprintf("%s:%d", ServerBind, ServerPort),
		Handler: loggedMux,
	}

	slog.Info("server started", slog.String("bind", ServerBind), slog.Int("port", ServerPort))
	if err := server.ListenAndServe(); err != nil {
		slog.Error("server failed", "error", err)
	}
}
