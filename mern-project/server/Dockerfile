# Use an official Node.js runtime as a parent image
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json into the container
COPY ./package*.json ./

# Install any dependencies defined in package.json
RUN npm install

# Copy the rest of your application code into the container
COPY ./ ./

# Expose the port that the server will run on
EXPOSE 5050

# Define the command to run the app using 'node server.mjs'
CMD ["node", "server.mjs"]



