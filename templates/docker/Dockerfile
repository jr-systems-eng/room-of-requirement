# syntax=docker/dockerfile:1
FROM __BASE_IMAGE__

WORKDIR /app

# Copy dependency metadata first when the language/build tool can benefit from layer caching.
COPY . /app

# Run build/install steps here.
# RUN __INSTALL_COMMAND__

USER __NON_ROOT_USER__

EXPOSE __PORT__

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD __HEALTHCHECK_COMMAND__ || exit 1

CMD ["__COMMAND__"]
