FROM python:3.13.3-slim

ARG UID=10001
ARG GID=10001

# Install git with retry logic and cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create group and user in a single RUN command to reduce layers
RUN groupadd -g ${GID} app && \
    useradd -m -u ${UID} -g ${GID} -s /usr/sbin/nologin app && \
    mkdir /app && chown -R app:app /app

# Switch to the non-root user
USER app

# Clone the URLClassifier exceptions manager
ARG TARGET_BRANCH=main
RUN git clone --depth 1 --branch ${TARGET_BRANCH} https://github.com/mozilla/url-classifier-exceptions-manager.git /app

WORKDIR /app

# Copy requirements and install dependencies
RUN python -m pip install --no-cache-dir -r requirements.txt

# Install the package for the app user only (no root needed)
RUN python -m pip install --no-cache-dir . --upgrade --user

# Add user's local bin to PATH
ENV PATH="/home/app/.local/bin:$PATH"

# Copy and setup the startup script
COPY --chown=app:app --chmod=0755 entrypoint.sh /app/entrypoint.sh

# Set the entrypoint to use our startup script
ENTRYPOINT ["/app/entrypoint.sh"]
