# ------------- Base image used for both build targets  -------------
FROM clfoundation/sbcl:2.2.4 AS base
ARG SITENAME

RUN apt-get update \
    && apt-get install -y libev4

# Dummy user to specify home directory for Quicklisp install
RUN addgroup "${SITENAME}-user" \
    && adduser --ingroup "${SITENAME}-user" --home /home/site --disabled-password "${SITENAME}-user"
USER "${SITENAME}-user"

ENV QUICKLISP_ADD_TO_INIT_FILE=true
RUN /usr/local/bin/install-quicklisp

WORKDIR /home/site/quicklisp/local-projects/"${SITENAME}"
USER root

# Download tailwind.css executable
RUN curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/download/v3.4.17/tailwindcss-linux-x64 \
    && chmod +x tailwindcss-linux-x64 \
    && mv tailwindcss-linux-x64 tailwindcss

COPY . .


# ------------- Development image  -------------
FROM base as dev

# System user to launch app
RUN addgroup --system "${SITENAME}" \
    && adduser --ingroup "${SITENAME}" --shell /bin/false --home /home/site --disabled-password "${SITENAME}"
RUN chown -R "${SITENAME}:${SITENAME}" /home/site
USER "${SITENAME}"

ENTRYPOINT ["sbcl", "--load", "start.lisp"]
CMD ["--bind", "0.0.0.0", "--port", "3000", "--swank-port", "4005", "--debug"]

EXPOSE 3000 4005


# ------------- Production image  -------------
FROM base as prod

RUN ./tailwindcss -i ./public/styles.css -o ./public/layout.css --minify \
    && rm tailwindcss

# System user to launch app
RUN addgroup --system "${SITENAME}" \
    && adduser --ingroup "${SITENAME}" --shell /bin/false --home /home/site --disabled-password "${SITENAME}"
RUN chown -R "${SITENAME}:${SITENAME}" /home/site
USER "${SITENAME}"

ENTRYPOINT ["sbcl", "--load", "start.lisp"]
CMD ["--bind", "0.0.0.0", "--port", "3000"]

EXPOSE 3000
