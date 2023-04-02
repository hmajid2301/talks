FROM node:18-alpine as node

FROM node as aggregator 
RUN mkdir -p /tmp/reveal /dist/scripts

ENV REVEAL_VERSION 4.4.0
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

WORKDIR /tmp/reveal/

# Build minified js, css, copy plugins, etc. 
RUN node_modules/gulp/bin/gulp.js build
COPY index.html favicon.ico slides.md ./
COPY images ./images/
COPY css/dracula.css ./dist/dracula.css
COPY css/code.css ./dist/code.css

RUN mv /tmp/reveal /dist/reveal
# For some reasons libintl is only needed by envsubst in dev
RUN mkdir -p /dist/lib/ 
RUN cp /usr/lib/libintl.so.8 /dist/lib/

FROM node AS production
COPY --from=aggregator /dist /
EXPOSE 8000
EXPOSE 35729
CMD [ "npm", "run", "start", "--prefix", "/reveal/", "--", "--host", "0.0.0.0"]