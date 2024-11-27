# Dockerfile for the backend
FROM node:18

WORKDIR /app

# Copy package.json and package-lock.json from the server folder
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all server-related files into the container
COPY . ./

EXPOSE 5050

# Start the Express server
CMD ["node", "server.mjs"]
