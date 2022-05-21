# My journey using Docker as a development tool

## By Haseeb Majid

---

# What is Docker ?

---

# Why use Docker ?

---

# Example Code

- Simple FastAPI Web Service
- Virtualenv
  - C libs ?

---

# Folder Structure

Our folder structure should look something like this at the moment:

```tree
# ADD TREE STRUCTURE HERE NO DOCKER
```

---

# Basic Docker Image

Create a new image called `Dockerfile` at the root of our project.

```dockerfile
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

COPY ./requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app
```

---

# Let's run it

```bash
docker build -t api .
docker run api -p 80:8080
```

We can do better than this

---

# docker-compose

What is it ?

- yaml ?

```bash
docker-compose up --build
```

We can do even better

---

# Makefile

What is it ? create a new file called `Makefile` at the root of our project.

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

---

# App Dependencies

What if our app depends on a Database ? SFTP Server ?

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

---

# Folder Structure

Our folder structure should look something like this:

```tree
# ADD TREE STRUCTURE HERE
```

---

# What about tests ?

Imagine we had a test like so

We can also dockerise the code that runs our tests

---- 

# Update our makefile

```makefile
.PHONY: test
test: build ## Run the tests
	@docker-compose run app pytest
```

and much like how did before we can do:

```makefile
make test
```

----

Key word being where postgres is the name of the service that the app depends on

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

# Run this in CI ? 

So far we have improved our life locally! We can do better still.
How about our running our CI jobs in Docker as well ? 

We create this at `.github/workflows/branch.yml`

----

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

<!-- TODO: Screenshot of pipeline here -->

----

# Dockerise our dev tasks

We can also use Docker to run other dev related tasks such as pre-commit hooks (linting/formatting etc)

Let's update our makefile to look like this:

```makefile
.PHONY: lint
lint: ## Runs the lint scripts
	@docker-compose run --rm app pre-commit run --all-files
```

Then to run our linter we can do:

```
make lint
```

# Can we do better ? 

```Dockerfile
FROM python3.9

COPY ./requirements.txt start.sh /app/requirements.txt /app/start.sh

RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app

CMD ["/app/start.sh"]
```

----

Old image is big, we don't need most of the deps 1.2 GB -> 400 MB
 - Faster Upload/Download
	- Faster Builds
 - Less Storage
 - Reduces attack surface
 - Less things that can break


----

But we are installing our dev dependencies still all of our deployments will include
`pre-commit` why ?

First split our requirements into two files:

A normal `requirements.txt`

```
ipython
pre-commit
pytest
```

and `requirements.prod.txt`

```
fastapi
```

----

# Multistage images

```Dockerfile
FROM python:3.9 as builder # A base image used to buid our other images

COPY requirements.prod.txt ./

RUN pip install --no-cache-dir -r /requirements.prod.txt && \
	rm /requirements.prod.txt

FROM build as development # Image used for development

COPY requirements.txt start.sh /app

RUN pip install --no-cache-dir -r /requirements.txt && \
	rm -r /requirements.txt

WORKDIR /app
COPY . /app

EXPOSE 80

CMD ["/app/start.sh"]


FROM python:3.9-slim as production # Image used for production

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH=/app

COPY start.sh /app

COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

COPY . /app

EXPOSE 80

CMD ["/app/start.sh"]
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

# Appendix

 - Devcontainer in VSCode
 - docker-compose/Docker Python intreperter in Pycharm

<!-- TODO: Make a joke about seeking files -->
<!-- TODO: write tests -->
<!-- TODO: postgres changes to code -->
<!-- TODO: build targets makefile -->
<!-- TODO: code highlighting -->
<!-- TODO: revealjs file names in codeblocks -->