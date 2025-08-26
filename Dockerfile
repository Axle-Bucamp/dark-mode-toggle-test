# Dockerfile for DarkModeToggle React App

# Use Node.js 18 as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application source code
COPY . .

# Build Tailwind CSS (precompile styles)
RUN npm run build

# Expose port for the React app
EXPOSE 3000

# Command to start the app
CMD ["npm", "start"]