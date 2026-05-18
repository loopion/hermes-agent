FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git curl ca-certificates bash xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash -u 1001 hermes

USER hermes
WORKDIR /home/hermes

# Install Hermes Agent (skip browser — VPS headless)
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
    | bash -s -- --skip-browser

# Add local bin to PATH
ENV PATH="/home/hermes/.local/bin:$PATH"
ENV HOME="/home/hermes"
ENV HERMES_HOME="/home/hermes/.hermes"

# Copy entrypoint
COPY --chown=hermes:hermes entrypoint.sh /home/hermes/entrypoint.sh
RUN chmod +x /home/hermes/entrypoint.sh

VOLUME ["/home/hermes/.hermes"]

ENTRYPOINT ["/home/hermes/entrypoint.sh"]
CMD ["gateway"]
