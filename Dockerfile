ARG ENV=prod

FROM node:14.18.1-alpine3.14 as node
FROM nginxinc/nginx-unprivileged:1.21.3-alpine as nginx


FROM node as aggregator 
RUN mkdir -p /tmp/reveal /dist/scripts

ENV REVEAL_VERSION 4.3.1
RUN apk add curl
RUN curl -SLO "https://github.com/hakimel/reveal.js/archive/${REVEAL_VERSION}.tar.gz" \
	&& tar xzf ${REVEAL_VERSION}.tar.gz && \
	rm *.tar.gz && \
	cd /reveal.js-${REVEAL_VERSION}  && \
	mv package.json package-lock.json /tmp/reveal/

# Speed up build by removing dependencies that are large and not needed for this use case
# qunit -> pupeteer -> chrome
WORKDIR /tmp/reveal
RUN sed -i '/^.*node-qunit-puppeteer.*$/d' package.json
RUN npm install

# Install envsubst to be used for index.html templating in final image
RUN apk add gettext # For envsubst -> if libaries are missing, find out with: ldd $(which envsubst)
RUN mkdir -p /dist/usr/bin/
RUN cp /usr/bin/envsubst /dist/usr/bin

# Copy remaining web resources later for better caching
RUN cp -r /reveal.js-${REVEAL_VERSION}/* /tmp/reveal/
# Remove qunite dependency (see above)
RUN sed -i '/^const qunit.*$/d' gulpfile.js

FROM aggregator AS dev-aggregator
WORKDIR /tmp/reveal
# Build minified js, css, copy plugins, etc. 
RUN node_modules/gulp/bin/gulp.js build
RUN mv /tmp/reveal /dist/reveal
# For some reasons libintl is only needed by envsubst in dev
RUN mkdir -p /dist/lib/ 
RUN cp /usr/lib/libintl.so.8 /dist/lib/
COPY index.html images/ css/ favicon.ico slides.md /dist/reveal/


FROM node AS dev
COPY --from=dev-aggregator /dist /
EXPOSE 8000
EXPOSE 35729
ENTRYPOINT [ "npm", "run", "start", "--prefix", "/reveal/", "--", "--host", "0.0.0.0"]


FROM aggregator AS prod-aggregator
WORKDIR /tmp/reveal
RUN mkdir -p /dist/usr/share/nginx/ /dist/reveal/
# Package only whats necessary for static website 
RUN node_modules/gulp/bin/gulp.js package
RUN unzip reveal-js-presentation.zip -d /dist/reveal/
# Serve web content at same folder in dev and prod: /reveal. This does not work with buildkit.
RUN ln -s /reveal /dist/usr/share/nginx/html


FROM nginx AS prod
COPY --from=prod-aggregator --chown=nginx /dist /
EXPOSE 8080
ENTRYPOINT [ "nginx", "-g", "daemon off;"]

# Pick final image according to build-arg
FROM ${ENV}