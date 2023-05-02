package main

import (
	"log"
	"net/http"

	"github.com/labstack/echo/v5"
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/models"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
	_ "gitlab.com/hmajid2301/talks/an-intro-to-pocketbase/example/migrations"
)

var _ models.Model = (*Hello)(nil)

type Hello struct {
	models.BaseModel
	Message string `db:"message" json:"message"`
}

func (c *Hello) TableName() string {
	return "hello"
}

func main() {
	app := pocketbase.New()
	migratecmd.MustRegister(app, app.RootCmd, &migratecmd.Options{
		Automigrate: true,
	})

	bindAppHooks(app)

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}

func bindAppHooks(app core.App) {
	app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
		e.Router.POST("/hello", func(c echo.Context) error {
			hello := &Hello{
				Message: "Hi 👋, welcome to London Gophers!",
			}

			err := app.Dao().Save(hello)
			if err != nil {
				return err
			}

			return c.NoContent(http.StatusCreated)
		},
			apis.ActivityLogger(app),
			apis.RequireRecordAuth(),
		)
		return nil
	})
}
