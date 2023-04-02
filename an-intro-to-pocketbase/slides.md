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

---

# What is PocketBase?

> Open Source backend, for your next SaaS and Mobile app in 1 file

notes:

- 

----

# Similar Products

- Firebase
- Supabase
- Amplify

----

![I don't understand](images/firebase-supabase.webp)

----

# What is a Backend as a Service (BaaS)?

Handle the basic repetitive tasks: 

- Authentication
- Database Management 
- Email Verification

----

# Why use PocketBase?

- Runs from a single binary
  - Embedded SQLite DB
- Written in Go
   - Use as a framework
- Easy to use Dashboard (UI)
  - Written in Svelte

---

## Terminology

- Collection: Is a SQLite table
- Record: Is a single entry in a collection

---

## Demo

[PocketBase](http://localhost:8080/_/)

notes:

- Collections
  - Fields
  - API Rules
- Admin Account
- Logs

---

## Use as a Framework


```go
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

```go
# main.go

import (
    "net/http"

    "github.com/labstack/echo/v5"
    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
)

...

app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
    e.Router.GET("/hello", handler, middlewares)
    return nil
})
```

notes:

- echo V5 server

---

## Client Code

```js
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://127.0.0.1:8090');

await pb.send("/hello", {
    // for all possible options check
    // https://developer.mozilla.org/en-US/docs/Web/API/fetch#options
    query: { "abc": 123 },
});
```

---

## Database

```go
record, err := app.Dao().FindRecordById("comments", "RECORD_ID")
```

---

## Expand Relations

![Expand DB Schema](images/expand.png)

----

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

---

## Migrations

```go
// main.go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/plugins/migratecmd"

    // you must have have at least one .go migration file in the "migrations" directory
     _ "yourpackage/migrations"
)

func main() {
    app := pocketbase.New()

    migratecmd.MustRegister(app, app.RootCmd, &migratecmd.Options{
        Automigrate: true, // auto creates migration files when making collection changes
    })

    // ...
}
```

> When you deploy the final executable on your production server, the new migrations will be auto applied with the start of the application.

---

## Testing

```bash
./pocketbase serve --dir="./test_pb_data"
```

----

```go
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

    // setup the test ApiScenario app instance
    setupTestApp := func() (*tests.TestApp, error) {
        testApp, err := tests.NewTestApp(testDataDir)
        if err != nil {
            return nil, err
        }
        // no need to cleanup since scenario.Test() will do that for us
        // defer testApp.Cleanup()

        bindAppHooks(testApp)

        return testApp, nil
    }

    scenarios := []tests.ApiScenario{
        {
            Name:   "try as authenticated admin",
            Method: http.MethodGet,
            Url:    "/hello",
            RequestHeaders: map[string]string{
                "Authorization": adminToken,
            },
            ExpectedStatus:  200,
            ExpectedContent: []string{"Hello world!"},
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

- Not stable API
- Scale?

---

# Any Questions?

- Code: https://gitlab.com/hmajid2301/talks/an-intro-to-pocketbase
- Slides: https://haseebmajid.dev/talks/an-intro-to-pocketbase/

----

# Useful Links

- [PocketBase](https://pocketbase.io/docs/)
- [Awesome PocketBase](https://github.com/benallfree/awesome-pocketbase)
- [Fireship Video on PocketBase](https://www.youtube.com/watch?v=Wqy3PBEglXQ)