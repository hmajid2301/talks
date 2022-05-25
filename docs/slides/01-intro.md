# My journey using Docker 🐳 as a development tool

<small>By Haseeb Majid</small>

---

# Agenda

- Introduction to Docker 
- Basic Docker image
- docker-compose
  - Makefiles
  - Docker and CI
- Slimmer Docker image
- Multistage builds
- Poetry
- Docker and SSH

---

# About me

<ul>
  <li class="fragment">Avid 🏏 cricket fan</li>
  <li class="fragment">ZOE: Personalised Nutrition Startup
      <ul>
          <li class="fragment">https://joinzoe.com</li>
      </ul>
  </li>
  <li class="fragment">Personal Details
      <ul>
          <li class="fragment">https://haseebmajid.dev</li>
          <li class="fragment">https://gitlab.com/hmajid2301/</li>
          <li class="fragment">https://github.com/hmajid2301/</li>
      </ul>
  </li>
</ul>

---

# What is Docker ?

<ul>
  <li class="fragment">Docker is an open source containerisation platform</li>
  <li class="fragment">Allow us to package applications into containers</li>
  <li class="fragment">Containers run independently of each other
      <ul>
          <li class="fragment">Leverages resource isoaltion of linux keneral (such as c-groups and namespaces)</li>
      </ul>
  </li>
</ul>

----

# Why use Docker ?

<ul>
  <li class="fragment">Containers are very "light-weight"</li>
  <li class="fragment">Reproducible builds
      <ul>
          <li class="fragment">All you need is Docker (cli tool) installed locally
      </ul>
  </li>
  <li class="fragment">OS Independent</li>
  <li class="fragment">Portability can be deployed on many platforms
      <ul>
          <li class="fragment">GCP, AWS, Azure etc
      </ul>
  </li>
</ul>

----

# Image vs contianer

- Closely related but separate concepts
- A container is an instance of an image
- When you start/run an image it becomes a container
- Image is a recipe, containers are the cake
   - We can make many cakes from the a given recipe

----

<img width="80%" height="auto" data-src="images/works-on-my-machine.jpeg">

---

# Example Code

<ul>
  <li class="fragment">Simple FastAPI Web Service
      <ul>
          <li class="fragment">Interacts with Postgres database</li>
      </ul>
  
  </li>
  <li class="fragment">It allows us to get and add new users</li>
</ul>

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