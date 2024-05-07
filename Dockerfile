FROM clfoundation/sbcl:latest
ARG SITENAME=site

RUN apt-get update \
    && apt-get install -y libev4

# Dummy user to specify home directory for Quicklisp install
RUN addgroup "${SITENAME}-user" \
    && adduser --ingroup "${SITENAME}-user" --home /home/site --disabled-password "${SITENAME}-user"
USER "${SITENAME}-user"

ENV QUICKLISP_ADD_TO_INIT_FILE=true
RUN /usr/local/bin/install-quicklisp

WORKDIR /home/site/quicklisp/local-projects/"${SITENAME}"
COPY . .

USER root

# System user to launch app
RUN addgroup --system "${SITENAME}" \
    && adduser --ingroup "${SITENAME}" --shell /bin/false --home /home/site --disabled-password "${SITENAME}"
RUN chown -R "${SITENAME}:${SITENAME}" . \
    && chown -R "${SITENAME}:${SITENAME}" /home/site
USER "${SITENAME}"

ENTRYPOINT ["sbcl", "--load", "start.lisp"]
CMD ["--port", "3000"]

EXPOSE 3000
