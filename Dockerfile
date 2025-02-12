# Use a base image compatible with linux/amd64
FROM debian

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        wget \
        curl \
        jq \
        unzip \
        git \
        openssh-client && \
    rm -rf /var/lib/apt/lists/*
# Install Atlantis (latest amd64 binary)
RUN wget https://github.com/runatlantis/atlantis/releases/latest/download/atlantis_linux_amd64.zip -O atlantis.zip && \
    unzip atlantis.zip -d /usr/local/bin && \
    rm atlantis.zip && \
    chmod +x /usr/local/bin/atlantis

# Install OPA (latest amd64 binary)
RUN curl -L -o /usr/local/bin/opa https://openpolicyagent.org/downloads/v1.1.0/opa_linux_amd64_static && \
    chmod +x /usr/local/bin/opa
# Install Terraform (latest amd64 binary)
RUN wget https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_linux_amd64.zip -O tf.zip && \
    unzip tf.zip -d /usr/local/bin && \
    rm tf.zip && \
    chmod +x /usr/local/bin/terraform
#Verify
# Verify installations
RUN atlantis version && \
    opa version

# Set the working directory
WORKDIR /atlantis

# Expose the default Atlantis port
EXPOSE 4141

# Set the entrypoint to run Atlantis
ENTRYPOINT ["atlantis"]
CMD ["server"]