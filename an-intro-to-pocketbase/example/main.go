package main

import (
	"log"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
	// _ "gitlab.com/hmajid2301/talks/an-intro-to-pocketbase/example/migrations"
)

func main() {
	app := pocketbase.New()
	migratecmd.MustRegister(app, app.RootCmd, &migratecmd.Options{
		Automigrate: true,
	})

	err := app.Bootstrap()
	if err != nil {
		log.Fatal(err)
	}

	app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
		e.Router.GET("/hello", handler, middlewares)
		return nil
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
