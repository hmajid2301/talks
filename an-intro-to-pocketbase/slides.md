# An Introduction to PocketBase: 

[A Go-Based Backend as a Service]()

<small>by Haseeb Majid</small>

notes:

- Code & Slides shared at the end

---

# About Me

- Haseeb Majid
  - A software engineer
  - https://haseebmajid.dev
- Loves cats 🐱
- Avid cricketer 🏏 #BazBall

----

<img width="45%" height="auto" data-src="images/side_project.png">

---

# What is PocketBase?

> Open Source backend, for your next SaaS and Mobile app in 1 file

----

# Similar Products

- Firebase
- Supabase
- Amplify

----

![I don't understand](images/firebase-supabase.jpg)

----

# What is a Backend as a Service (BaaS)?

Handle the basic repetitive tasks

notes:

- Authentication
- Database Management 
- Email Verification

----

# Why use PocketBase?

- Runs from a single binary
- Written in Go
   - Extend as framework
- Easy to use Dashboard

notes:
- embeds SQLite DB
- UI Written in Svelte
- Scale can handle 10k connections on $6 VPS
- Super easy to self-host

---

## Demo

[PocketBase](http://localhost:8090/_/)

notes:

`- Collections
  - Fields
  - API Rules
- Admin Account
- Logs`

---

## Use as a Framework


```go [5-9|11-17]
// main.go

package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
)

func main() {
    app := pocketbase.New()

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

----

```bash
go run main.go serve --http=localhost:8080
```

---

## Add a Route

```go [14-18]
# main.go

import (
    "net/http"

    "github.com/labstack/echo/v5"
    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
)

func main() {
    //...

    app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
        e.Router.POST("/hello", handler, middlewares)
        return nil
    })
}

```

notes:

- echo V5 server

----

```go
app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
    e.Router.POST("/hello", func(c echo.Context) error {
        return c.NoContent(http.StatusCreated)
    },
        apis.ActivityLogger(app),
        apis.RequireRecordAuth(),
    )
    return nil
})
```

notes:

- actual function
- some middlewares
   - log request
   - check user is auth

----

## Client Code

```js
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

await pb.send("/hello", {
    // for all possible options check
    // https://developer.mozilla.org/en-US/docs/Web/API/fetch#options
});
```

notes:

- fetch

---

## Add Record to DB

```go [6-8|11-15|16-18]
// ...
import 	"github.com/pocketbase/pocketbase/models"

app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
    e.Router.POST("/hello", func(c echo.Context) error {
        collection, err := app.Dao().FindCollectionByNameOrId("comments")
        if err != nil {
            return err
        }

        record := models.NewRecord(collection)
        record.Set("post", "<postid>")
        record.Set("user", "<userid>")
        record.Set("message", "Hi 👋, London Gophers!")

        if err := app.Dao().SaveRecord(record); err != nil {
            return err
        }
        return c.NoContent(http.StatusCreated)
    },
    // ...
    )
    return nil
})
```

----

## Expand Relations

![Expand DB Schema](images/expand.png)

----

## Client

```js
pb.collection("comments").getList(1, 30, {
    expand: "users"
}),
```

----

```json [11|12-17]
{
    // ...
    "items": [
        {
            // ...
            "id": "lmPJt4Z9CkLW36z",
            "collectionName": "comments",
            "post": "WyAw4bDrvws6gGl",
            "user": "FtHAW9feB5rze7D",
            "message": "Example message...",
            "expand": {
                "user": {
                    "id": "FtHAW9feB5rze7D",
                    "collectionId": "srmAo0hLxEqYF7F",
                    "collectionName": "users",
                    // ...
                }
            }
        }
    ]
}
```

----

## Migrations

```go [11|16-19]
// main.go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/plugins/migratecmd"

    // you must have have at least one .go migration file in the "migrations" directory
    _ "gitlab.com/hmajid2301/talks/an-intro-to-pocketbase/example/migrations"
)

func main() {
    app := pocketbase.New()

    migratecmd.MustRegister(app, app.RootCmd, &migratecmd.Options{
        Automigrate: true, // auto creates migration files when making collection changes
    })

    // ...
}
```

---

## SQLite

- Does it Scale?
    - Write-Ahead Logging (WAL mode)

notes:

----

## What is WAL Mode?

<iframe src="images/wal_animation.html" width="1000" height="500"  frameborder="0">

notes:

- SQLite groups rows together into 4KB chunks called "pages".
 - benefits 
- POSIX system call `fsync()` commits buffered data to permanent storage or disk
- `fsync()` is expensive

----

## Why use WAL Mode? 

- Is significantly faster in most scenarios. 
- WAL uses many fewer `fsync()` operations
- Provides more concurrency as a writer does not block readers.

notes:

- No network file support
- Not atomic when commits across separate DB's
- Might be slightly slower 1-2% for read heavy and very rare write apps
- In rollback mode, you can have concurrent readers but not readers & writers


---

## Testing


```go [29-41|43-45]
package main

import (
	"net/http"
	"testing"

	"github.com/pocketbase/pocketbase/tests"
	"github.com/pocketbase/pocketbase/tokens"
)

const testDataDir = "./test_pb_data"

func TestHelloEndpoint(t *testing.T) {
	recordToken, err := generateRecordToken("users", "test@example.com")
	if err != nil {
		t.Fatal(err)
	}

	setupTestApp := func() (*tests.TestApp, error) {
		testApp, err := tests.NewTestApp(testDataDir)
		if err != nil {
			return nil, err
		}

		bindAppHooks(testApp)
		return testApp, nil
	}

	scenarios := []tests.ApiScenario{
		{
			Name:   "try to get response",
			Method: http.MethodPost,
			Url:    "/hello",
			RequestHeaders: map[string]string{
				"Authorization": recordToken,
			},
			ExpectedStatus:  201,
			ExpectedContent: nil,
			TestAppFactory:  setupTestApp,
		},
	}

	for _, scenario := range scenarios {
		scenario.Test(t)
	}
}

func generateRecordToken(collectionNameOrId string, email string) (string, error) {
	app, err := tests.NewTestApp(testDataDir)
	if err != nil {
		return "", err
	}
	defer app.Cleanup()

	record, err := app.Dao().FindAuthRecordByEmail(collectionNameOrId, email)
	if err != nil {
		return "", err
	}

	return tokens.NewRecordAuthToken(app, record)
}
```

---

## Caveats

- Need to self-host
- Does not have a stable API yet
- Can only scale vertically

----

<img width="50%" height="auto" data-src="images/colour.jpg">

---

# Any Questions?

- Code: https://gitlab.com/hmajid2301/talks/an-intro-to-pocketbase
- Slides: https://haseebmajid.dev/talks/an-intro-to-pocketbase/

----

# Useful Links

- [PocketBase](https://pocketbase.io/docs/)
- [Awesome PocketBase](https://github.com/benallfree/awesome-pocketbase)
- [Fireship Video on PocketBase](https://www.youtube.com/watch?v=Wqy3PBEglXQ)
- [WAL Mode Explained](https://www.youtube.com/watch?v=86jnwSU1F6Q)
- [My App Built Using PocketBase](https://gitlab.com/bookmarkey)