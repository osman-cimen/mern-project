# Use an official Node.js runtime as a parent image
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json into the container
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your application code into the container
COPY . ./

# Expose the port that the frontend will run on
EXPOSE 3000

# Command to run the React app
CMD ["npm", "start"]
