# My journey using Docker 🐳 as a development tool

<small>By Haseeb Majid</small>

---

# About me

- Haseeb Majid
  - A Software Engineer
  - https://haseebmajid.dev
- Avid 🏏 cricketer
- I work for 🥑 ZOE 
  - Personalised Nutrition Startup
  - https://joinzoe.com 
- 🐱 Loves cats

---

# What is Docker ?

- Docker is a containerisation platform
- Allows us to package apps
- Containers run independently

notes:

Indepdent:

  - open-source containerisation platform
  - Leverages resource isolation of linux keneral (such as c-groups and namespaces)

----

# Why use Docker ?

- Containers are "light-weight"
- Reproducible builds
- OS Independent 
- Portability
    - GCP, AWS, Azure etc

notes:

- Light-weight as compared with VMs
- App can be deployed anywhere not Docker
- Portability, your app can be deployed on many platforms

----

# Image vs container

- Closely related
- Image -> Containers
  - Image is a recipe 📜
  - Containers are the cake 🎂

notes:

- Closely related but separate concepts
- When you start/run an image it becomes a container
- We can make many cakes from a given recipe

----

<img width="80%" height="auto" data-src="images/works-on-my-machine.jpeg">

---

# Example Code

- Simple FastAPI Web Service 
  - Interacts with DB
- It allows us to get and add new users

notes:

- FastAPI is a "async" Python Web framework, similar to Flask
- Postgres database


----

# Folder Structure


```bash
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
black==22.3.0
fastapi==0.78.0
psycopg2-binary==2.9.3
pytest==7.1.2
sqlalchemy==1.4.36
uvicorn==0.15.0
```

----

# Our First Image

```dockerfile [1|3|5|7]
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

COPY ./requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app
```

notes:

Create a new file called `Dockerfile`

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

- Manage multiple Docker containers
- Existing tool `docker-compose`
  - V2 called `docker compose`
- Use `docker compose` today


notes:

- Easy way to manage multiple containers
- Aimed at single host development
- There is a similar tool called docker-compose
  - The new version is called docker compose
  - Will be deprecated soon
- New version written in Golang as a Docker plugin

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

----

<img width="60%" height="auto" data-src="images/what-if-i-told-you-we-can-do-better.jpg">

---

# App Dependencies

- App depends on a Database
  - Dockerise it

----

```yaml [3-4|9-16|22-30]
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

```
docker compose up --build
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

notes:

Equivalent docker compose vs docker comamnds


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

``` [4-5]
example
├── app
│   └── ...
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── tests
    └── ...
```

---

# dev tasks

- Run tests in Docker
    - `pytest` runner

notes:

Assume using pytest

----

```bash
docker compose run app pytest
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

- Docker running locally
- Can we use Docker in CI? 

notes:

- Can we use Docker in CI as well

----

<img width="80%" height="auto" data-src="images/say-it-one-more-time.jpeg">

----


```yaml [3-7|10-16|16]
name: Check changes on branch

on:
  push:
    branches:
      - "*"
      - "!main"

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: docker compose run app pytest
```

notes:

- We create this at `.github/workflows/branch.yml`

----

<img width="80%" height="auto" data-src="images/nope-we-can-do-better.jpg">

---

# Smaller image

- Image is large 
- Redundant Deps
- Less storage
  - 1.05GB -> 215MB

notes:

- Lots of extra dependencies we don't need
  - Reduces attack surface
  - Less things that can break

----

```Dockerfile [1|3|11]
FROM python:3.9.8-slim

COPY ./requirements.txt start.sh /app

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app

WORKDIR /app

CMD [ "bash", "/app/start.sh" ]
```

---

# Dependencies


- Dev dependencies in Docker image
  - Don't need `pytest` in prod
- Less storage
  - 215MB -> 201MB

notes:

- We are installing our dev dependencies inside of our Docker image such as pytest
- We don't need pytest in our production image

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
  <code data-trim data-noescape data-line-numbers="1-6|8-20|23-40|31-33" class="dockerfile">
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

---

# Dependency Management

- Two files for deps
- Use poetry

notes:
  - Two files to manage deps
  - Use a tool like poetry to manage both for us

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

- Private git repository
- Inject an SSH key
  - At build time

notes:

Can we inject an ssh key only during build time

----

<img width="80%" height="auto" data-src="images/anakin-ssh.webp" />

notes:

- Less chance of accidently committing

----

```bash
poetry add git+ssh@gitlab.com:banter-bus/omnibus.git
```

<pre>
  <code data-trim data-noescape data-line-numbers="4-5" class="toml">
  [tool.poetry.dependencies]
  python = "^3.9"
  fastapi = "^0.70.0"
  omnibus = { git = "ssh://git@gitlab.com:banter-bus/omnibus.git",
              rev = "0.2.5" }
  psycopg2-binary = "^2.9.3"
  SQLAlchemy = "^1.4.36"
  uvicorn = "^0.17.6"
  </code>
</pre>


----

```dockerfile [3-7|12]
FROM base as builder

RUN apt-get update && \
    apt-get install openssh-client git -y && \
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

```
docker compose build --ssh default
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
      - name: Run Tests
        run: docker compose run app pytest
```

---

# Key Takeaways

- Dockerise everything
- Leverage Docker in CI
- Use multi-stage builds
  - Dev and prod images

---

# Even better

- Devcontainer in VSCode
- Docker Python interpreter in Pycharm
- Common base image
- Makefile
- [Breaking Down Docker by Nawaz Siddiqui](https://kubesimplify.com/breaking-down-docker#heading-virtual-machines)

---

# Code & Slides

- Code: https://gitlab.com/hmajid2301/developing-with-docker-slides
- Slides: https://hmajid2301.gitlab.io/developing-with-docker-slides

---

<h1 style="color:white;">Any Questions ?</h1>

<!-- .slide: data-background="https://i.gifer.com/4A5.gif" -->

---

# My journey using Docker 🐳 as a development tool

<small>By Haseeb Majid</small>

<!-- TODO: Make a joke about seeking files -->
<!-- TODO: separate sections -->