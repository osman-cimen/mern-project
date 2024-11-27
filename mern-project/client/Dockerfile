# Step 1: Use the official Node.js image as the base image
# Use the official Node.js image for React build
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json for npm install
COPY ./package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the React app code
COPY ./ /app

# Expose port 3000 for the React app
EXPOSE 3000

# Start the React development server
CMD ["npm", "start"]

