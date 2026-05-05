FROM mcr.microsoft.com/vscode/devcontainers/base:bookworm

COPY ./.devcontainer/certificate.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Set up HashiCorp repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

# Set up Google Cloud SDK repository
RUN wget -O- https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  gpg --dearmor | \
  tee /usr/share/keyrings/cloud.google.gpg > /dev/null

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list

# Install Terraform & Google Cloud CLI
RUN apt-get update && apt-get install -y \
  wget \
  unzip \
  terraform \
  google-cloud-cli \
  direnv \
  && rm -rf /var/lib/apt/lists/*

# Setup Git
RUN git config --global user.email "dscott98@gmail.com" && git config --global user.name "Dustin Scott"

# Set up direnv hook
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bash_profile
