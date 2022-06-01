# My journey using Docker 🐳 as a development tool

<small>By Haseeb Majid</small>

---

# Agenda

- Introduction to Docker 
- Basic Docker image
- docker compose
  - Makefiles
  - Docker and CI
- Slimmer Docker image
- Multistage builds
- Poetry
- Docker and SSH

---

# About me

- Haseeb Majid  <!-- .element: class="fragment" -->
  - A Software Engineer
  - https://haseebmajid.dev
- Avid 🏏 cricketer  <!-- .element: class="fragment" -->
- I work for 🥑 ZOE  <!-- .element: class="fragment" -->
  - Personalised Nutrition Startup
  - https://joinzoe.com 
- 🐱 Loves cat  <!-- .element: class="fragment" -->

---

Link to slides and code examples:

- https://gitlab.com/hmajid2301/developing-with-docker-slides

---

# What is Docker ?

> Docker is an open platform for developing, shipping, and running applications. Docker enables you to separate your applications from your infrastructure so you can deliver software quickly. - Docker

----

- Docker is an open source containerisation platform  <!-- .element: class="fragment" -->
- Allow us to package applications into containers  <!-- .element: class="fragment" -->
- Containers run independently of each other  <!-- .element: class="fragment" -->
  - Leverages resource isolation of linux keneral (such as c-groups and namespaces)  <!-- .element: class="fragment" -->

----

# Why use Docker ?

- Containers are very "light-weight" as comapared with VMs  <!-- .element: class="fragment" -->
- Reproducible builds  <!-- .element: class="fragment" -->
  -   All you need is Docker (cli tool) installed locally
- OS Independent  <!-- .element: class="fragment" -->
- Portability, your app can be deployed on many platforms  <!-- .element: class="fragment" -->
    - GCP, AWS, Azure etc

notes:

- light-weight as compared with VMs
- App can be deployed anywhere not Docker

----

# Image vs contianer

- Closely related but separate concepts <!-- .element: class="fragment" -->
- When you start/run an image it becomes a container <!-- .element: class="fragment" -->
- Image is a recipe, containers are the cake <!-- .element: class="fragment" -->
   - We can make many cakes 🎂 from a given recipe 📜

----

<img width="80%" height="auto" data-src="images/works-on-my-machine.jpeg">

---

# Example Code

- Simple FastAPI Web Service <!-- .element: class="fragment" -->
    - Interacts with Postgres database
- It allows us to get and add new users <!-- .element: class="fragment" -->

notes:

- FastAPI is a "async" Python Web framework, similar to Flask

----

# Folder Structure


```
example
├── app
│   ├── __init__.py
│   ├── config.py
│   ├── db.py
│   ├── main.py
│   └── models.py
├── requirements.txt
└── tests
    ├── __init__.py
    └── test_example.py
```

---


```
fastapi==0.78.0
pre-commit==2.19.0
psycopg2-binary==2.9.3
pytest==7.1.2
sqlalchemy==1.4.36
uvicorn==0.15.0
```

----

# Basic Docker Image

Create a new file called `Dockerfile` at the root of our project folder.

----

```dockerfile [1|3|5|7]
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

COPY ./requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app
```

notes:

Used to be the example on FastAPI but since been removed

----

# Let's run it

```bash
docker build -t app .
docker run -p 80:80 app

# Access app on http://localhost
```

----

<img width="80%" height="auto" data-src="images/do-better.png">

---

# docker compose

- An easy way to spin up multiple Docker container
- Great for development
  - Aimed at single host deployments

----

- There is a similar tool called docker-compose <!-- .element: class="fragment" -->
  - The new version is called docker compose
  - Will be deprecated soon
- New version written in Golang as a Docker plugin <!-- .element: class="fragment" -->
- We will use docker compose today <!-- .element: class="fragment" -->

----

```yaml [3-5|6-7]
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

Run it with:

```bash
docker compose up --build
```

----

<img width="80%" height="auto" data-src="images/what-if-i-told-you-we-can-do-better.jpg">

---

# App Dependencies

- What if our app depends on a Database <!-- .element: class="fragment" -->
  - Well we can also Dockerise those as well <!-- .element: class="fragment" -->

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

<pre class="stretch">
  <code data-trim data-noescape class="bash">
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
  </code>
</pre>


----

```
docker compose up --build
```

----

<div class="stretch">
  <iframe data-src="https://asciinema.org/a/JshvHbHjApBXg7YkmYjnsIDs7/iframe?autoplay=1&speed=2&loop=1" height="100%" width="100%"></iframe>
</div>

----

<div class="stretch">
  <iframe data-src="https://asciinema.org/a/Wn4hwzFXTiXLVnOa0YNk2JRcs/iframe?autoplay=1&speed=1&loop=1" height="100%" width="100%"></iframe>
</div>

----

<div class="stretch">
  <iframe data-src="https://asciinema.org/a/7e8sPYfzCCqhI2eP5TQcDXvHz/iframe?autoplay=1&speed=2&loop=1" height="100%" width="100%"></iframe>
</div>

----

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

- We can run our tests in Docker containers too!
    - Let's assume we are using pytest to run our tests

----

```bash
docker-compose run app pytest
```

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

---

# Docker and CI

- So far we have improved our life locally! <!-- .element: class="fragment" -->
- How about our running our CI jobs in Docker as well <!-- .element: class="fragment" -->
- Let's improve it <!-- .element: class="fragment" -->

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

----

<img width="80%" height="auto" data-src="images/nope-we-can-do-better.jpg">

---

# Smaller Docker image

- Image is large  <!-- .element: class="fragment" -->
- Lots of extra dependencies we don't need  <!-- .element: class="fragment" -->
    - Reduces attack surface  <!-- .element: class="fragment" -->
    - Less things that can break  <!-- .element: class="fragment" -->
- Less storage  <!-- .element: class="fragment" -->

----

```Dockerfile [1|3|11]
FROM python:3.9.8-slim

COPY ./requirements.txt start.sh /app

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app

WORKDIR /app

CMD [ "bash", "/app/start.sh" ]
```

----

1.05GB -> 215MB

---

# Dev vs Prod Dependencies

- We are installing our dev dependencies inside of our Docker image such as pytest  <!-- .element: class="fragment" -->
- We don't need pytest in our production image  <!-- .element: class="fragment" -->

----

<img width="80%" height="auto" data-src="images/dependencies-dependencies-everywhere.jpg">

----

`requirements.prod.txt`

```
fastapi==0.78.0
psycopg2-binary==2.9.3
sqlalchemy==1.4.36
uvicorn==0.15.0
```

and `requirements.txt`

```
-r requirements.prod.txt

black==22.3.0
pytest==7.1.2
```

notes:

Split into two files

---

# Multistage images

<pre class="stretch">
  <code data-trim data-noescape data-line-numbers="1-6|8-20|23-40" class="dockerfile">
  FROM python:3.9.8 as builder

  COPY requirements.prod.txt /app/requirements.prod.txt

  RUN pip install --no-cache-dir -r /app/requirements.prod.txt && \
    rm /app/requirements.prod.txt

  FROM builder as development

  COPY requirements.txt start.sh /app/

  RUN pip install --no-cache-dir -r /app/requirements.txt && \
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
  COPY --from=builder /usr/local/lib/python3.9/site-packages/ \
      /usr/local/lib/python3.9/site-packages/

  COPY ./app /app

  EXPOSE 80

  CMD ["bash", "/app/start.sh"]
  </code>
</pre>


----

```yaml [4-6]
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    command: bash /app/start.sh --reload
    depends_on:
      - postgres
    environment:
      - # ...
    volumes:
      - ./:/app
    ports:
      - 80:80

```

----

215MB -> 201MB

---

# Dependency Management

- Two files to manage dependencies <!-- .element: class="fragment" -->
- Use a tool like poetry to manage both for us <!-- .element: class="fragment" -->

----

<img width="80%" height="auto" data-src="images/poetry.webp">

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
black = "^22.3.0"
pytest = "^7.1.2"

# ...
```

----

<pre class="stretch">
  <code data-trim data-noescape data-line-numbers="3-15|20-27|30-39|42-50" class="dockerfile">
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
  COPY ./app ./

  EXPOSE 80
  CMD ["bash", "/app/start.sh"]


  FROM builder as development

  RUN poetry install

  WORKDIR /app
  COPY . .

  EXPOSE 80
  CMD ["bash", "/app/start.sh", "--reload"]
  </code>
</pre>

----

# Folder Structure

``` [6-7]
example
├── app
│   └── ...
├── docker-compose.yml
├── Dockerfile
├── pyproject.toml
├── poetry.lock
└── tests
    └── ...
```

---

# Private Deps 

- No PyPI
- Private git repository
- Inject an SSH key

notes:

Can we inject an ssh key only during build time ? 

----

<img width="80%" height="auto" data-src="images/anakin-ssh.webp" />

----

```bash
poetry add git@gitlab.com:banter-bus/omnibus.git
```

<pre>
  <code data-trim data-noescape data-line-numbers="4-5" class="toml">
  [tool.poetry.dependencies]
  python = "^3.9"
  fastapi = "^0.70.0"
  omnibus = { git = "git@gitlab.com:banter-bus/omnibus.git",
              rev = "0.2.5" }
  psycopg2-binary = "^2.9.3"
  SQLAlchemy = "^1.4.36"
  uvicorn = "^0.17.6"
  </code>
</pre>


----

Then update our docker image to include

```dockerfile [3-7|12]
FROM base as builder

RUN apt-get update && \
    apt-get install openssh-client -y && \
    mkdir -p -m 0600 \
    ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts && \
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

----

<div class="stretch">
  <iframe data-src="https://asciinema.org/a/LNUbPGRehtxI2OuhVBhWHMNYi/iframe?autoplay=1&speed=2&loop=1&t=20" height="100%" width="100%"></iframe>
</div>

----

# CI Changes

```yml [9-11]
# ...

jobs:
  # ...
  test:
    # ...
    steps:
      - uses: actions/checkout@v3
      - uses: webfactory/ssh-agent@v0.5.4
        with:
          ssh-private-key: ${{ secrets.PRIVATE_SSH_KEY }}
      - uses: google-github-actions/setup-gcloud@v0.6.0
      - run: |-
          gcloud --quiet auth configure-docker
      - name: Run Tests
        run: make test
```

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
	@docker compose build --ssh default


.PHONY: start
start: build ## Starts the FastAPI web service
	@docker compose up


.PHONY: test
test: build ## Run the tests
	@docker compose run app pytest
```

Then we can do

```bash
make start
```

----

<div class="stretch">
  <iframe src="https://asciinema.org/a/EZcPiQEFC4AbK9q8tXa5ZurB0/iframe?autoplay=1&speed=4&loop=1" height="100%" width="100%"></iframe>
</div>

---

# Even better ? 

Here are a list of things we can do even better

- Devcontainer in VSCode
- Docker Python intreperter in Pycharm
- Common base image
- Add more make targets

Useful extra reading:

- [Breaking Down Docker by Nawaz Siddiqui](https://kubesimplify.com/breaking-down-docker#heading-virtual-machines)

---

<h1 style="color:white;">Any Questions ?</h1>

<!-- .slide: data-background="https://i.gifer.com/4A5.gif" -->

<!-- TODO: Make a joke about seeking files -->
<!-- TODO: separate sections -->