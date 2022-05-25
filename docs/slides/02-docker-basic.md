# Basic Docker Image

Create a new file called `Dockerfile` at the root of our project folder.

----

```dockerfile [1|3|5|7]
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

COPY ./requirements.txt /app/requirements.txt

RUN apt-get update && apt-get install -y git && \
	pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app
```

----


```
fastapi==0.78.0
pre-commit==2.19.0
psycopg2-binary==2.9.3
pytest==7.1.2
sqlalchemy==1.4.36
uvicorn==0.15.0
```

----

# Let's run it

```bash
docker build -t app .
docker run app -p 80:80

# Access app on http://localhost
```

----

<img width="80%" height="auto" data-src="images/do-better.png">

---

# docker-compose

- An easy way to spin up multiple Docker container
- Great for development
  - Aimed at single host deployments

----

```yaml [5-7|8-9]
version: "3.8"

services:
  app:
    build: 
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./app:/app
    ports:
      - 80:80
```

We can run it with

```bash
docker-compose up --build
```

----

<img width="80%" height="auto" data-src="images/what-if-i-told-you-we-can-do-better.jpg">

---

# Makefile

- Think of it like a cookbook
- Run repeatable tasks
- Don't have to memorise complicated cli commands

----

Create a new file called `Makefile` at the root of our project.

```makefile
.PHONY: build
build: ## Builds the Docker images needed by our app
	@docker-compose build


.PHONY: start
start: build ## Starts the FastAPI web service
	@docker-compose up
```

Then we can do

```bash
make start
```

----

<div class="stretch">
  <iframe src="https://asciinema.org/a/EZcPiQEFC4AbK9q8tXa5ZurB0/iframe?autoplay=1&speed=4&loop=1" height="100%" width="100%"></iframe>
</div>


----

<img width="60%" height="auto" data-src="images/makefile.jpg">

---

# App Dependencies

<ul>
  <li class="fragment">What if our app depends on a Database
      <ul>
          <li class="fragment">Well we can also Dockerise those as well</li>
      </ul>
  </li>
</ul>

----

```yaml [3-4|9-16|22-30]
version: "3.8"

volumes:
  postgres_data: {}

services:
  app:
    image: Dockerfile
    depends_on:
      - postgres
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_PORT=5432
    volumes:
      - ./:/app
    ports:
      - 80:8080

  postgres:
    image: postgres:13.4
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DATABASE=postgres
      - POSTGRES_PASSWORD=postgres
    ports:
      - 5432:5432
```

----

```bash

# Start Commands: 

docker network create --driver bridge workspace_network
docker volume create  postgres_data
docker run --environment "POSTGRES_USER=postgres" \
  --environment "POSTGRES_HOST=postgres" \
  --environment "POSTGRES_DATABASE=postgres" \
  --environment "POSTGRES_PASSWORD=postgres" \
  --environment "POSTGRES_PORT=5432" \
  --volume "./:/app" --publish "80:8080" \
  --network workspace_network --name workspace_app \
  --detach Dockerfile
docker run --volume "postgres_data:/var/lib/postgresql/data" \
--environment "POSTGRES_DATABASE=postgres" \
--environment "POSTGRES_PASSWORD=postgres" \
--publish "5432:5432" --network workspace_network \ 
--name workspace_postgres --detach postgres:13.4

# Delete Commands: 

docker stop workspace_app
docker rm workspace_app
docker stop workspace_postgres
docker rm workspace_postgres
docker network rm workspace_network
```

---

<img width="60%" height="auto" data-src="images/everyone-gets-a-docker-container.jpg">

---

# Folder Structure

``` [4-6]
example
├── app
│   └── ...
├── docker-compose.yml
├── Dockerfile
├── Makefile
├── requirements.txt
└── tests
    └── ...
```

---

# Dockerise our dev tasks

<ul>
  <li class="fragment">We can run our tests in Docker containers too!
      <ul>
          <li class="fragment">Let's assume we are using pytest to run our tests</li>
      </ul>
  </li>
</ul>

---

```makefile
.PHONY: test
test: build ## Run the tests
	@docker-compose run app pytest
```

then

```bash
make test
```

----

```yaml [7-9|10]
services:
 app:
    build:
      context: .
      dockerfile: Dockerfile
    # ...
    depends_on:
      - postgres

  postgres:
	# ...
```

----

- We can also use Docker to run other dev tasks
   - such as pre-commit hooks (linting/formatting etc)

----

```makefile
.PHONY: lint
lint: ## Runs the lint scripts
	@docker-compose run --rm app pre-commit run --all-files
```

Then to run our linter we can do:

```bash
make lint
```

----

<div class="stretch">
  <iframe src="https://asciinema.org/a/VAWXyRBsKyO47bZ1IBVFparAN/iframe?autoplay=1&speed=2&loop=1" height="100%" width="100%"></iframe>
</div>

---

# Docker and CI

<ul>
  <li class="fragment">So far we have improved our life locally!</li>
  <li class="fragment">How about our running our CI jobs in Docker as well</li>
  <li class="fragment">Let's improve it</li>
</ul>


----

<img width="80%" height="auto" data-src="images/say-it-one-more-time.jpeg">

----

We create this at `.github/workflows/branch.yml`


```yaml [3-7|10-20|21-31]
name: Check changes on branch

on:
  push:
    branches:
      - "*"
      - "!main"

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v3
        with:
          python-version: "3.9"
          cache: "pip"
      - name: Run Lint Jobs
        run: make lint
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: make test
```