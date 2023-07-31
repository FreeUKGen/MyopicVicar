# Use the Ruby 2.7.4 image from the DockerHub
FROM ruby:2.7.4

# Set an environment variable to store where the app is installed to inside the Docker image
ENV RAILS_ROOT /var/www/myopicvicar
RUN mkdir -p $RAILS_ROOT/vendor/extensions

# Set the working directory inside the Docker image
WORKDIR $RAILS_ROOT

# Update package list and install nodejs and MySQL client
RUN apt-get update -qq && \
    apt-get install -y curl gnupg && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs default-mysql-client

# Update bundler to version 2.2.16
RUN gem install bundler:2.2.16

# Copy the main application into the image
COPY . .

# Install the gems
RUN bundle install

# Expose port 3000 from the container to the host
EXPOSE 3000

# Start the main process
CMD ["rails", "server", "-b", "0.0.0.0"]