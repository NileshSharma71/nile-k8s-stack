#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Igniting Nile-k8s-stack local environment..."

# Start Minikube with heavy-duty resources for the PLG logging stack
minikube start --driver=docker --cpus=4 --memory=8192

# Enable critical addons for routing and autoscaling
echo "📦 Enabling Ingress controller..."
minikube addons enable ingress

echo "📊 Enabling Metrics Server..."
minikube addons enable metrics-server

echo "✅ Minikube cluster is live and ready for Helm deployments!"