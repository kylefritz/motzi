# Use the standard Ubuntu 22.04 base image
FROM mcr.microsoft.com/devcontainers/base:jammy

# 1. Install Postgres (Client & Server) and Redis
# We install 'libpq-dev' so the 'pg' gem can compile.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    postgresql \
    postgresql-contrib \
    redis-server \
    libpq-dev \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# 2. Configure Postgres to allow the 'vscode' user to connect easily
# We replace the default auth methods with 'trust' for local connections
RUN sed -i 's/scram-sha-256/trust/g' /etc/postgresql/*/main/pg_hba.conf \
    && sed -i 's/md5/trust/g' /etc/postgresql/*/main/pg_hba.conf

# 3. Install 'mise' manually (since the feature failed)
# This will allow your bin/setup script to manage Ruby 3.3.10 and Bun versions automatically
RUN curl https://mise.run | MIS_INSTALL_PATH=/usr/local/bin/mise sh

# 4. Add mise to the shell for interactive use
RUN echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc
