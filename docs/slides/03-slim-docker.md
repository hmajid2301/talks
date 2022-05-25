<img width="80%" height="auto" data-src="images/nope-we-can-do-better.jpg">

---

# Smaller Docker image

<ul>
  <li class="fragment">Image is large</li>
  <li class="fragment">Lots of extra dependencies we don't need
      <ul>
          <li class="fragment">Reduces attack surface</li>
          <li class="fragment">Less things that can break</li>
      </ul>
  </li>
  <li class="fragment">Less storage</li>
</ul>

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

<ul>
  <li class="fragment">We are installing our dev dependencies inside of our Docker image such as `pre-commit`</li>
  <li class="fragment">We don't need `pre-commit` for our production image</li>
</ul>

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

pre-commit==2.19.0
pytest==7.1.2
```

notes:

Split into two files

---

# Multistage images

<pre class="stretch">
  <code data-trim data-noescape data-line-numbers="1-6|8-21|24-40" class="dockerfile">
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

<ul>
  <li class="fragment">Two files to manage dependencies</li>
  <li class="fragment">Use a tool like `poetry` to manage both for us</li>
</ul>


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
ipython = "^8.3.0"
pre-commit = "^2.19.0"

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

``` [7-8]
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

# Private Deps 

<ul>
  <li class="fragment">No PyPI</li>
  <li class="fragment">Private git repository</li>
  <li class="fragment">Inject an SSH key</li>
</ul>


notes:

Can we inject an ssh key only during build time ? 

----

<img width="80%" height="auto" data-src="images/anakin-ssh.webp>

----

# docker-compose vs docker compose

<ul>
  <li class="fragment">Migrate docker-compose to Golang
      <ul>
          <li class="fragment">We can inject our SSH key just at build time</li>
      </ul>
  </li>
</ul>

---

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
    apt-get install git openssh-client -y && \
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
  <iframe src="https://asciinema.org/a/LNUbPGRehtxI2OuhVBhWHMNYi/iframe?autoplay=1&speed=2&loop=1&t=20" height="100%" width="100%"></iframe>
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