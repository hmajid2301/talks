# My Journey Using Docker as a Development Tool:


From Zero to Hero

<!-- .slide: data-background="#fac828" -->

---

# About Me

- Haseeb Majid
  - A Software Engineer
  - https://haseebmajid.dev
- Avid 🏏 cricketer
- I work for 🥑 ZOE 
  - https://joinzoe.com 
  - Personalised nutrition startup
  - Health Study
- 🐱 Loves cats

---

# Who is this talk for?

- Have used Docker
  - But not an expert
- Know basic CLI commands
- Want to use Docker in CI

notes:

- Learn more about using 
- in CI
- Multistage builds

---

# Example Code

- Simple FastAPI Web Service 
  - Interacts with DB
- It allows us to get and add new users
- Poetry for dependency

notes:

- FastAPI is a "async" Python Web framework, similar to Flask
- Postgres database

----

# Why Docker?

- Reproducible builds
  - Easy setup developers
  - OS Independent

notes:

- Upgrading MacOS nothing builds locally virtualenv
- Docker daemon running

----

<img width="80%" height="auto" data-src="images/works-on-my-machine.jpeg">

---

# My First Image

```Dockerfile [1|3-18|20-21|23-24|26-27|29]
FROM python:3.9.8

ENV PYTHONUNBUFFERED=1 \
	PYTHONDONTWRITEBYTECODE=1 \
	PYTHONPATH="/app" \
	PIP_NO_CACHE_DIR=off \
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

WORKDIR $PYSETUP_PATH
COPY pyproject.toml poetry.lock ./

RUN pip install poetry==$POETRY_VERSION && \
	poetry install

WORKDIR /app
COPY . .

CMD [ "bash", "/app/start.sh" ]
```

notes:

PYTHONDONTWRITEBYTECODE: prevents writing out pyc files
PYTHONUNBUFFERED: sent straight to terminal real time

Create a new file called `Dockerfile`

Used to be the example on FastAPI but since been removed

----

# Let's run it

```bash
docker build -t app .
docker run -p 80:80 app

# Access app on http://localhost
```

notes:

Maps port 80 on the host to port 80 in the docker container

---

# App Dependencies

- App depends on a Database
  - Dockerise it


notes:

- Easy to extend docker compose file

----

# Without Docker

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql.service

sudo -u postgres createuser --interactive
sudo -u postgres createdb test
```

notes:

How we might have to install it like so

----

# With Docker

```bash
  docker run --volume "postgres_data:/var/lib/postgresql/data" \
  --environment "POSTGRES_DATABASE=postgres" \
  --environment "POSTGRES_PASSWORD=postgres" \
  --publish "5432:5432" \
  --detach postgres:13.4
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

```yaml [4|5-10|11-12|13-14|16|16-24]
# docker-compose.yml

services:
  app:
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_PORT=5432
    volumes:
      - ./:/app
    ports:
      - 80:80

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

# Before

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

# After

```
docker compose up --build
```

----

<img width="60%" height="auto" data-src="images/deeper.jpeg">

----

# Port Binding

```yaml [7]
# docker-compose.yml

services:
  app:
    # ...
    ports:
      - 80:80
```

----

```yaml [5]
services:
  app:
    # ...
    ports:
      - 127.0.0.1:80:80
```

notes:

- Bind to host `0.0.0.0`
- It forwards it to be accessible on every network interface on your system 

----

# Summary

- Dockerise the app
- Docker dependencies (DB)
- Use `docker compose` to manage multiple Docker containers

----

<img width="60%" height="auto" data-src="images/what-if-i-told-you-we-can-do-better.jpg">

---

# Running Tests

- Run tests in Docker
  - `pytest` runner
- Consistent Environment

notes:

- Same local and CI
- Different environments
- Different dependencies locally and CI or production
- Imagine postgres version
- Seek files

----

```bash
docker compose run app pytest
```

```yaml [6-8|10]
services:
 app:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - postgres
    # ...

  postgres:
	# ...
```

---

# CI Pipeline

- Docker running locally
- Can we use Docker in CI? 

notes:

- Next thing I looked at doing was now using Docker in CI
- Can we use Docker in CI as well
- Easier to move CI

----

<img width="80%" height="auto" data-src="images/say-it-one-more-time.jpeg">

----

# Before

```yaml [3-7|14-17|18-22|25]
name: Check changes on branch

on:
  push:
    branches:
      - "*"
      - "!main"

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python 3.9
        uses: actions/setup-python@v3
        with:
          python-version: 3.9
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install pytest
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
      - name: Test with pytest
        run: |
          pytest
```

----


```yaml [11]
name: Check changes on branch

#...

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: Run Tests
        run: docker compose run app pytest
```

----

# Summary

- Dockerise development tasks
  - tests
  - linting
  - DB migrations
- Use Docker on CI
  - Local environment = CI enviromnent

----

<img width="80%" height="auto" data-src="images/nope-we-can-do-better.jpg">

---

# Smaller image

- Image is large 
- Redundant Deps
- Less storage

notes:

So this is what I did next!

- Slower upload times
  - Save 30 seconds CI
- Lots of extra dependencies we don't need
  - Reduces attack surface
  - Less things that can break

----

```Dockerfile [1]
FROM python:3.9.8-slim

WORKDIR $PYSETUP_PATH
COPY pyproject.toml poetry.lock ./

RUN pip install poetry==${POETRY_VERSION} && \
	poetry install

WORKDIR /app
COPY . .

CMD [ "bash", "/app/start.sh" ]
```

---

# Alpine vs Slim

- Lack of support
  - Standard PyPI wheels
  - musl vs glibc
- Image Size

notes:

  glibc: Standard C library 

  Alpine
    - Comptability Issues
    - Standard PyPI wheels don’t work on Alpine

----

# Comparison

|                  | Before     | After      |
|------------------|------------|------------|
| Size             | 1 GB       | 280 MB     |
| First time build | 75 Seconds | 30 Seconds |
| CI Pipeline Job  | 2 Minutes 40 Seconds | 1 Minute 57 Seconds  |

----

# Summary

- Aim to user smaller base images
- Reduce unnecessary depdencies
- Save time during build time

----

<img width="80%" height="auto" data-src="images/improvement.jpeg">

---

# Dependencies

- Dev dependencies in Docker image
  - Don't need `pytest` in prod

notes:

Then I did this:

- We are installing our dev dependencies inside of our Docker image such as pytest
- We don't need pytest in our production image

----

# Multistage Builds

<img width="80%" height="auto" data-src="images/hands-up.jpg">

Notes:

- Put your hand up if you've heard of multistage builds

----

<img width="150%" height="auto" data-src="images/build.jpg">

Notes:

- Multiple `FROM` statements
- Copy build artefacts from a previous stage

----

# Image

```dockerfile [1|20-27|23-40|41-49|43]
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


FROM builder as development

RUN poetry install

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["bash", "/app/start.sh", "--reload"]


FROM base as production

COPY --from=builder $VENV_PATH $VENV_PATH

WORKDIR /app
COPY . .

EXPOSE 80
CMD ["bash", "/app/start.sh"]
```


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
      - 127.0.0.1:80:80

```

----

# !Root

```dockerfile [3-5|7]
FROM base as production

RUN addgroup --gid 1000 --system app \
    && adduser --no-create-home --shell \
    /bin/false --disabled-password --uid 1000 --system --group app

USER app
COPY --from=builder $VENV_PATH $VENV_PATH

# ...
```

notes:

- Don't want to run as root
- Reduces chance of exploit
- Most applications don't need root permissions
- After this all commands are run as `app` user

----

# Comparison

|                  | Before     | After [1]     |
|------------------|------------|------------|
| Size             | 280 MB     | 200 MB     |
| First time build | 30 Seconds | 35 seconds |

<small>[1] Building for production target</small>

----

# Cache From

```yaml [6-7]
services:
  app:
    build:
      context: .
      target: development
      cache_from:
        - registry.gitlab.com/haseeb-slides/developing-with-docker-slides/python-image:latest
    command: bash /app/start.sh --reload
    # ....
```

notes: 

- If the provided image and your current build have layers in common, you get the same speed up as if the image had been built on the same machine.
- Without using --cache-from our build script would always have to execute every command in the Dockerfile, as the build cache would be empty:
- saves about 5 seconds on CI

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

```toml [4-5]
  [tool.poetry.dependencies]
  python = "^3.9"
  fastapi = "^0.70.0"
  omnibus = { git = "ssh://git@gitlab.com:banter-bus/omnibus.git",
              rev = "0.2.5" }
  psycopg2-binary = "^2.9.3"
  SQLAlchemy = "^1.4.36"
  uvicorn = "^0.17.6"
```


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

----

# Comparison

|                  | Before [1]    | After [2]     |
|------------------|------------|------------|
| Size             | 400 MB     | 200 MB     |
| First time build | 39 Seconds | 46 seconds |

<small>[1] Assuming there was no multistage build</small>
<small>[2] Building for production target</small>

----

# Summary

- Use multistage builds for slimmer production images
- Use non-root users
- Leverage SSH injection during build time


---

# Key Takeaways

- Dockerise everything
- Leverage Docker in CI
- Use multi-stage builds
  - Dev and prod images

---

# Even better

- Common base image
- Makefile
- Devcontainer in VSCode
- Docker Python interpreter in Pycharm

----

# Articles & Tools

- [Breaking Down Docker by Nawaz Siddiqui](https://kubesimplify.com/breaking-down-docker#heading-virtual-machines)
- [Announcing Compose V2 General Availability](https://www.docker.com/blog/announcing-compose-v2-general-availability/)
- [Caching Docker layers on serverless build hosts with multi-stage builds](https://andrewlock.net/caching-docker-layers-on-serverless-build-hosts-with-multi-stage-builds---target,-and---cache-from/)
- [Using Alpine can make Python Docker builds 50× slower](https://pythonspeed.com/articles/alpine-docker-python/)
- [Docker Slim](https://github.com/docker-slim/docker-slim)
- [Dive](https://github.com/wagoodman/dive)
- [Anchore image scan](https://github.com/anchore/anchore-engine)

---

# Any Questions ?

- Code: https://gitlab.com/haseeb-slides/docker-as-a-dev-tool
- Slides: https://docker-as-a-dev-tool.haseebmajid.dev/

----

# Appendix 

- [Arrows in Multi-stage build Image](https://www.flaticon.com/free-icons/arrow)
- [Hand Illustration](https://www.vecteezy.com/vector-art/1777476-open-hands-up-of-different-types-of-skins)