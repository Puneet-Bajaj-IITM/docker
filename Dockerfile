# Use the official Ubuntu 20.04 LTS image
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and upgrade packages
RUN apt-get update && apt-get -y upgrade

# Install necessary packages
RUN apt-get install -y \
    software-properties-common \
    python3.9 \
    python3.9-venv \
    python3-pip \
    git \
    nodejs \
    npm \
    wget

# Add deadsnakes PPA and install Python 3.9
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.9 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

# Clone RapidPro repository
RUN git clone --depth 1 --branch main https://github.com/nyaruka/rapidpro

# Navigate to the temba directory
WORKDIR /rapidpro/temba

# Create a symbolic link to settings.py.dev
RUN ln -s settings.py.dev settings.py

# Navigate back to the parent directory
WORKDIR /rapidpro

# Install poetry
RUN pip install poetry

# Set up virtual environment
RUN python3.9 -m venv env

# Activate virtual environment
SHELL ["/bin/bash", "-c"]
RUN source env/bin/activate

# Install dependencies using poetry
RUN poetry install

# Run migrations
RUN python manage.py migrate

# Install lessc and coffeescript globally
RUN npm install -g less coffeescript

# Set environment variables
RUN echo 'MAILROOM_DB="postgres://temba:temba@localhost/temba?sslmode=disable"' >> /etc/environment && \
    echo 'INDEXER_DB="postgres://temba:temba@localhost/temba?sslmode=disable"' >> /etc/environment && \
    echo 'INDEXER_ELASTIC_URL="http://localhost:9200"' >> /etc/environment

# Expose Django server port
EXPOSE 8000

# Command to start the Django server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
