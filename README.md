MERN Stack Deployment on AWS EKS



+-------------------+            +--------------------+            +----------------------------------------+
|                   |            |                    |            |    (RUN ON A AWS EC2 ISTANCE)          |
|  Developer Code   +--(push)--->|    GitHub Repo     +-(trigger)-->          Jenkins Pipeline              |
|                   |            |                    |            |Create The Infrastructure with Terraform|
+-------------------+            +--------------------+            +----------------------------------------+
                                                                           |
                                                       +-------------------+-------------------+
                                                       |                                       |
                                             +--------------------+              +------------------------------+
                                             |                    |              |                              |
                                             |   Docker Build     |              |Push the images to DOCKER HUB |
                                             |                    |              |                              |
                                             +--------------------+              +------------------------------+
                                                        |
                                       +-------------------------------------------+
                                       |                                           |
                               +------------------+                     +-------------------+
                               |    Helm Deploy   |                     |                   |
                               |   Push the charts|--------------------->   AWS EKS Cluster |
                               |    S3 Bucket     |                     |                   |
                               +------------------+                     +-------------------+
                                                            |
                                      +-----------------------------------------------+
                                      |                                               |
                               +-------------------+                      +----------------------+
                               |                   |                      |                      |
                               | Prometheus        |                      |  Grafana             |
                               | (Monitoring)      |                      |  (Visualization)     |
                               |                   |                      |                      |
                               +-------------------+                      +----------------------+


KEY OBJECTIVES:

Dockerize the MERN stack (MongoDB, Express, React, Node.js).

Provision infrastructure using Terraform on AWS (EKS, VPC, IAM, and S3 for artifact storage).

Deploy using Helm and utilize Kubernetes features like StorageClasses, Autoscaling, and Load Balancers.

Automate CI/CD with Jenkins and GitHub integration.

Monitor with Prometheus and Grafana for real-time metrics.


*DOCKERIZING THE MERN STACK:*

**a. Backend (Node.js/Express) Dockerfile**


# Dockerfile for the backend
FROM node:18

WORKDIR /app

# Copy package.json and package-lock.json from the server folder
COPY ./server/package*.json ./

# Install dependencies
RUN npm install

# Copy all server-related files into the container
COPY ./server/ ./

EXPOSE 5050

# Start the Express server
CMD ["node", "server.mjs"]


**b. Frontend (React) Dockerfile**


# Use an official Node.js runtime as a parent image
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json into the container
COPY ./client/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your application code into the container
COPY ./client/ ./

# Expose the port that the frontend will run on
EXPOSE 3000

# Command to run the React app
CMD ["npm", "start"]

```

Also I use official mongo image for the database , cretaed docker images for server and client and push it for using the images on aws

I created a simple docker-compose file to test.

docker-compose.yml

version: '3.8'

services:
  backend:
    build:
      context: ./  # Set the build context to the root of the project
      dockerfile: ./server/Dockerfile  # Path to the backend Dockerfile
    container_name: backend
    ports:
      - "5050:5050"
    environment:
      - MONGO_URI=mongodb://mongo:27017/mern-app
    depends_on:
      - mongo
    networks:
      - mern-network
    restart: always

  mongo:
    image: mongo:latest
    container_name: mongo
    ports:
      - "27017:27017"
    networks:
      - mern-network
    restart: always

  frontend:
    build:
      context: ./  # Set the context to the frontend folder
      dockerfile: ./client/Dockerfile  # Path to the frontend Dockerfile
    container_name: frontend
    ports:
      - "3000:3000"
    networks:
      - mern-network
    restart: always

networks:
  mern-network:
    driver: bridge



***Provision Infrastructure with Terraform***

*Terraform Configuration for AWS Infrastructure
I used Terraform to provision AWS resources:*

EKS Cluster: Kubernetes orchestration.
VPC: Virtual Private Cloud for networking.
IAM Roles: For EKS cluster access.
S3 Bucket: For storing Helm charts, Docker images, and other deployment artifacts.
Terraform Provider Setup (AWS)

main.tf

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.vpc_name
  cidr   = var.vpc_cidr
  azs    = data.aws_availability_zones.available.names
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_nat_gateway = true
}

# EKS Cluster Configuration
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    eks_nodes = {
      desired_capacity = var.node_desired_capacity
      max_capacity     = var.node_max_capacity
      min_capacity     = var.node_min_capacity
      instance_type    = var.node_instance_type
    }
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# S3 Bucket for Artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = var.s3_bucket_name
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

variables.tf

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "mern-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets for the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "Private subnets for the VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mern-cluster"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.21"
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for artifacts"
  type        = string
  default     = "mern-stack-artifacts"
}

outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket
}




```
*Deploying with Helm, Autoscaling, and Load Balancing*
I deployed the MERN stack using Helm and configure autoscaling, load balancing, and storage classes.

Use **helm create mern-stack** command for creating a local helm chart also we can use an instant helm chart from artifacthub.

mern-stack/
  ├── charts/
  ├── templates/
      ├── backend-deployment.yaml
      ├── frontend-deployment.yaml
      ├── mongo-deployment.yaml
      ├── ingress.yaml
      ├── secret.yaml                  
      ├── network-policy.yaml          
      ├── rbac.yaml                    
      ├── pod-security-policy.yaml
  ├── values.yaml
  ├── Chart.yaml
**I created kubernetes manifest files for the deployment with helm chart**

*Backend (Node.js/Express) Deployment with Autoscaling and Load Balancer*


apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: osmancimen/mern-backend:latest
          ports:
            - containerPort: 5000
          env:
            - name: MONGO_URI
              value: "mongodb://mongo:27017/mern"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
  type: LoadBalancer
---
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50

*Frontend (React) Deployment*

apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: osmancimen/mern-frontend:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer

**MongoDB Deployment**

I deployed MongoDB in a Kubernetes pod using a StatefulSet with persistent storage, utilizing a convenient StorageClass.

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
spec:
  serviceName: "mongo"
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: mongo:latest
          volumeMounts:
            - name: mongo-data
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 5Gi
        storageClassName: gp2

*Automating CI/CD with Jenkins and GitHub Integration*

I used Jenkins to automate the build, test, push, and deployment process. 

First I created jenkins server on an ec2 instance using cloudformation :

AWSTemplateFormatVersion: '2010-09-09'
Description: Jenkins Server Setup with S3 and EKS Access

Parameters:
  KeyName:
    Type: String
    Description: Name of an existing EC2 KeyPair to enable SSH access.

Resources:
  # Security Group for Jenkins
  JenkinsSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow access to Jenkins
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          CidrIp: 0.0.0.0/0

  # IAM Role for EC2
  JenkinsEC2Role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - ec2.amazonaws.com
            Action:
              - sts:AssumeRole

  # IAM Policy for S3 and EKS Access
  S3EksAccessPolicy:
    Type: AWS::IAM::Policy
    Properties:
      PolicyName: S3EksAccessPolicy
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Action:
              - s3:ListBucket
              - s3:GetObject
              - s3:PutObject
            Resource:
              - "arn:aws:s3:::your-bucket-name"
              - "arn:aws:s3:::your-bucket-name/*"
          - Effect: Allow
            Action:
              - eks:DescribeCluster
            Resource:
              - "arn:aws:eks:your-region:your-account-id:cluster/your-cluster-name"
      Roles:
        - !Ref JenkinsEC2Role

  # IAM Instance Profile
  JenkinsInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref JenkinsEC2Role

  # Jenkins EC2 Instance
  JenkinsInstance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t2.medium
      KeyName: !Ref KeyName
      ImageId: ami-0d5d9d301c853a04a # Ubuntu 20.04 (Update with your region's AMI ID)
      SecurityGroupIds:
        - !Ref JenkinsSecurityGroup
      IamInstanceProfile: !Ref JenkinsInstanceProfile
      UserData:
        Fn::Base64: |
          #!/bin/bash
          apt-get update
          apt-get install -y openjdk-11-jdk curl
          curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee \
              /usr/share/keyrings/jenkins-keyring.asc > /dev/null
          echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
              https://pkg.jenkins.io/debian-stable binary/ | tee \
              /etc/apt/sources.list.d/jenkins.list > /dev/null
          apt-get update
          apt-get install -y jenkins
          systemctl start jenkins
          systemctl enable jenkins
          # Install Docker
          apt-get install -y docker.io
          usermod -aG docker jenkins
          systemctl restart jenkins

Outputs:
  JenkinsURL:
    Description: URL to access Jenkins
    Value: !Sub "http://${JenkinsInstance.PublicIp}:8080"



After this I went to the AWS CloudFormation console.
Created a new stack and uploaded the above template.
Provided the KeyPair name as a parameter.
I Connected to the jenkins server with remote-ssh and retrieved jenkins password using:

**sudo cat /var/lib/jenkins/secrets/initialAdminPassword** command

and then I connected the jenkins using output url and the password and username.

I instaalled Terraform Plugin, AWS Steps Plugin, Docker Pipeline Plugin, Kubernetes Plugin, Prometheus Metrics Plugin

then ı created a pipeline using below jenkinsfile

I added github credentials to jenkins using giithub personal token

I created a github webhooks in the github repository and so whenever a code change and merge the repository then my pipeline retrieve the new changes and build all environment. 





pipeline {
    agent any

    environment {
        REGISTRY = "<docker-repository>"
        IMAGE_BACKEND = "mern-backend"
        IMAGE_FRONTEND = "mern-frontend"
        KUBE_CONFIG = "/path/to/kubeconfig"
        S3_BUCKET = "mern-stack-artifacts"
        PROMETHEUS_CHART_PATH = "./monitoring/prometheus"
        GRAFANA_CHART_PATH = "./monitoring/grafana"
        TERRAFORM_DIR = "./terraform" // Path to Terraform configuration
    }

    stages {
        stage('Provision Infrastructure') {
            steps {
                script {
                    dir("${TERRAFORM_DIR}") {
                        sh "terraform init"
                        sh "terraform apply -auto-approve"
                    }
                }
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                script {
                    sh "docker build -t ${REGISTRY}/${IMAGE_BACKEND}:${GIT_COMMIT} ./backend"
                    sh "docker build -t ${REGISTRY}/${IMAGE_FRONTEND}:${GIT_COMMIT} ./frontend"
                    sh "docker push ${REGISTRY}/${IMAGE_BACKEND}:${GIT_COMMIT}"
                    sh "docker push ${REGISTRY}/${IMAGE_FRONTEND}:${GIT_COMMIT}"
                }
            }
        }

        stage('Upload Helm Charts to S3') {
            steps {
                script {
                    sh "aws s3 cp ./helm/ s3://${S3_BUCKET}/helm/ --recursive"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh "helm upgrade --install mern-stack ./helm --set backend.image=${REGISTRY}/${IMAGE_BACKEND}:${GIT_COMMIT} --set frontend.image=${REGISTRY}/${IMAGE_FRONTEND}:${GIT_COMMIT}"
                }
            }
        }

        stage('Deploy Monitoring Stack') {
            steps {
                script {
                    // Deploy Prometheus
                    sh "helm upgrade --install prometheus ${PROMETHEUS_CHART_PATH} --namespace monitoring --create-namespace"

                    // Deploy Grafana
                    sh "helm upgrade --install grafana ${GRAFANA_CHART_PATH} --namespace monitoring"
                }
            }
        }
    }
}




# mern-project
The troubles and troubleshooting

