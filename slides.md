---
title: My journey using Docker as a development tool
highlightTheme: "monokai"
---

# My journey using Docker as a development tool

<small>By Haseeb Majid</small>

---

# Agenda

- Introduction to Docker 
- Basic Docker image
- docker-compose
- Makefiles
- CI Pipeline

---

# About me

- Avid cricket fan
- <span class="fragment highlight-blue">ZOE</span>: Personalised Nutrition Startup
  - https://joinzoe.com
- https://haseebmajid.dev

---

# What is Docker ?

- Docker is an open source containerisation platform
- Allow us to package applications into containers
- Containers run independently of each other
  - leverage resource isoaltion of linux keneral (such as c-groups and namespaces)

----

# Why use Docker ?


- Containers are very "light-weight"
- Reproducible builds
  - All you need is Docker (cli tool) installed locally
- OS Independent
- Portability can be deployed on many platforms
  - GCP, AWS, Azure etc

----

<a href="#" class="navigate-down">
    <img width="80%" height="auto" data-src="https://miro.medium.com/max/800/1*DPS45Tufsih-zED3To4k6g.jpeg">
</a>

---

# Example Code

- Simple FastAPI Web Service
  - Interacts with Postgres database
- It allows us to get and add new users


----

# Folder Structure

Our folder structure should look like:

```
example
├── app
│   ├── config.py
│   ├── db.py
│   ├── __init__.py
│   ├── main.py
│   └── models.py
├── requirements.txt
└── tests
    ├── __init__.py
    └── test_example.py
```

---

# Basic Docker Image

Create a new file called `Dockerfile` at the root of our project folder.

----

```dockerfile
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

COPY ./requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

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
docker build -t api .
docker run api -p 80:8080
```

----

We can do better than this

<a href="#" class="navigate-down">
    <img width="80%" height="auto" data-src="https://pics.me.me/you-can-do-better-than-that-memes-com-17633693.png">
</a>


---

# docker-compose

- An easy way to spin up multiple Docker container
- Great for development
  - Aimed at single host deployments

----

```yaml
version: "3.8"

services:
  app:
    build: 
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./:/app
    ports:
      - 80:80
```

----

# How to run it?

```bash
docker-compose up --build
```

----

We can do even better

<a href="#" class="navigate-down">
    <img width="60%" height="auto" data-src="https://memegenerator.net/img/instances/56359362.jpg">
</a>

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

<a href="#" class="navigate-down">
    <img width="60%" height="auto" data-src="https://pbs.twimg.com/media/EEiCfp5XkAE9Wxv.jpg">
</a>


---

# App Dependencies

What if our app depends on a Database ? Well we can also Dockerise those as well.

<a href="#" class="navigate-down">
    <img width="60%" height="auto" data-src="https://memegenerator.net/img/instances/53695021.jpg">
</a>

----

```yaml
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

# As compared with normal Docker

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

# Folder Structure

Our folder structure now looks like:

```tree
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

# What about tests ?

We can run our tests in Docker containers too!
Imagine we use pytest to run our tests. We can then do the following.

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

We need to specify the `depends_on` keyword so that the `postgres` container is also created alongside the `app` container.

```yaml
services:
  app:
	# ...
    depends_on:
      - postgres

  postgres:
	# ...
```

----

# Dockerise our dev tasks

We can also use Docker to run other dev related tasks such as pre-commit hooks (linting/formatting etc)

----

Let's update our `Makefile` to look like this:

```makefile
.PHONY: lint
lint: ## Runs the lint scripts
	@docker-compose run --rm app pre-commit run --all-files
```

Then to run our linter we can do:

```
make lint
```

---

# Docker and CI

- So far we have improved our life locally! 
- How about our running our CI jobs in Docker as well
- Let's improve it

----

We create this at `.github/workflows/branch.yml`


```yaml
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

----

<a href="#" class="navigate-down">
    <img width="80%" height="auto" data-src="https://miro.medium.com/max/760/1*If2z6prJkD_EsW56HmJr5Q.jpeg">
</a>

---

# Can we do better ?

- Image is large
  - Old image 1.05 GB
  - New image 215 MB 
- Lots of extra dependencies we don't need
  - Reduces attack surface
  - Less things that can break
- Less storage

----

```Dockerfile
FROM python:3.9.8-slim

COPY ./requirements.basic.txt start.sh /app

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app

WORKDIR /app

CMD [ "bash", "/app/start.sh" ]
```

---

# Dev vs Prod Dependencies

- We are installing our dev dependencies inside of our Docker image such as `pre-commit`
- We don't need `pre-commit` for our production image
- 215MB -> 201MB


----

<a href="#" class="navigate-down">
    <img width="80%" height="auto" data-src="https://memegenerator.net/img/instances/72937228.jpg">
</a>

----

First split our requirements into two files:

A normal `requirements.txt`

```
-r requirements.prod.txt

pre-commit==2.19.0
pytest==7.1.2
```

and `requirements.prod.txt`

```
fastapi==0.78.0
psycopg2-binary==2.9.3
sqlalchemy==1.4.36
uvicorn==0.15.0
```

---

# Multistage images

```Dockerfile
FROM python:3.9.8 as builder

COPY requirements.prod.txt /app/requirements.prod.txt

RUN pip install --no-cache-dir -r /app/requirements.prod.txt && \
	rm /app/requirements.prod.txt

FROM builder as development

COPY requirements.txt start.sh /app/

RUN apt-get update && apt-get install git && \
	pip install --no-cache-dir -r /app/requirements.txt && \
	rm -r /app/requirements.txt

WORKDIR /app
COPY . /app

EXPOSE 80

CMD ["bash", "/app/start.sh", "--reload"]


FROM python:3.9.8-slim as production

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH=/app

COPY start.sh /app/start.sh

COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

COPY . /app

EXPOSE 80

CMD ["bash", "/app/start.sh"]
```

----

```dockerfile
FROM python:3.9.8 as builder

COPY requirements.prod.txt /app/requirements.prod.txt

RUN pip install --no-cache-dir -r /app/requirements.prod.txt && \
	rm /app/requirements.prod.txt

FROM builder as development

COPY requirements.txt start.sh /app/

RUN apt-get update && apt-get install git && \
	pip install --no-cache-dir -r /app/requirements.txt && \
	rm -r /app/requirements.txt

WORKDIR /app
COPY . /app

EXPOSE 80

CMD ["bash", "/app/start.sh", "--reload"]
```

----


```dockerfile
FROM python:3.9.8 as builder

COPY requirements.prod.txt ./

RUN pip install --no-cache-dir -r /requirements.prod.txt && \
	rm /requirements.prod.txt

# ...

FROM python:3.9.8-slim as production

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH=/app

COPY start.sh /app/start.sh

COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

COPY . /app

EXPOSE 80

CMD ["bash", "/app/start.sh"]
```

----

Our other code changes like

```yaml
services:
  app:
	# ...
    build:
      file: Dockerfile
      target: development
```

---

# Dependency Management

- Two files to manage dependencies
- Use a tool like `poetry` to manage both for us

----

We need a `pyproject.toml` file

```toml
# ...

[tool.poetry.dependencies]
python = "^3.9"
fastapi = "^0.78.0"
psycopg2-binary = "^2.9.3"
SQLAlchemy = "^1.4.36"
uvicorn = "^0.17.6"

[tool.poetry.dev-dependencies]
ipython = "^8.3.0"
pre-commit = "^2.19.0"

# ...
```

----

```dockerfile
FROM python:3.9.8-slim as base

ARG PYSETUP_PATH
ENV PYTHONPATH="/app"
ENV PIP_NO_CACHE_DIR=off \
	PIP_DISABLE_PIP_VERSION_CHECK=on \
	PIP_DEFAULT_TIMEOUT=100 \
	\
	POETRY_VERSION=1.1.11 \
	POETRY_HOME="/opt/poetry" \
	POETRY_VIRTUALENVS_IN_PROJECT=true \
	PYSETUP_PATH="/opt/pysetup" \
	POETRY_NO_INTERACTION=1 \
	\
	VENV_PATH="/opt/pysetup/.venv"

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"


FROM base as builder

RUN pip install poetry

WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

RUN poetry install --no-dev


FROM python:3.9.8-slim as production

USER app
COPY --from=builder $VENV_PATH $VENV_PATH

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["bash", "/app/start.sh"]


FROM builder as development

RUN poetry install

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["bash", "/app/start.sh", "--reload"]
```

----

```dockerfile
FROM base as builder

RUN pip install poetry

WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

RUN poetry install --no-dev
```

----

```dockerfile
FROM python:3.9.8-slim as production

USER app
COPY --from=builder $VENV_PATH $VENV_PATH

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["bash", "/app/start.sh"]
```

----

```dockerfile
FROM builder as development

RUN poetry install

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["bash", "/app/start.sh", "--reload"]
```

----

# Folder Structure

```
example
├── app
│   └── ...
├── docker-compose.yml
├── Dockerfile
├── Makefile
├── pyproject.toml
├── poetry.lock
└── tests
    └── ...
```


---

# Private Deps ? 

- No PyPI
- Private git repository
- Inject SSH key ? 

----

<a href="#" class="navigate-down">
    <img width="80%" height="auto" data-src="https://preview.redd.it/8txk53wez6d71.jpg?auto=webp&s=f04b16d5641ef3781da134b0afeeacebc5e1865e">
</a>

----

# docker-compose vs docker compose

- Migrate docker-compose to Golang
- `.ssh` flag
  - We can inject our SSH key just at build time

---

Update our `pyproject.toml` to include the private dep

```toml
[tool.poetry.dependencies]
python = "^3.9"
fastapi = "^0.70.0"
omnibus = { git = "git@gitlab.com:banter-bus/omnibus.git", rev = "0.2.5" }
psycopg2-binary = "^2.9.3"
SQLAlchemy = "^1.4.36"
uvicorn = "^0.17.6"
```

----

Then update our docker image to include

```dockerfile
FROM base as builder

RUN apt-get update && apt-get install git openssh-client -y && \
	mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts && \
	pip install poetry

WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

RUN --mount=type=ssh poetry install --no-dev
```

----

First add our ssh key

```bash
ssh-add ~/.ssh/id_rsa
```

Then we can do

```makefile
.PHONY: build
build: ## Builds the Docker images needed by our app
	@docker compose build --ssh default
```

---

# Appendix

- Devcontainer in VSCode
- Docker Python intreperter in Pycharm
- docker compose vs docker-compose

---

# Any Questions ?

<!-- .slide: data-background="https://i.gifer.com/4A5.gif" -->

<!-- TODO: Make a joke about seeking files -->
<!-- TODO: separate sections -->
