#!/bin/sh
set -o errexit


ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yaml --ask-become-pass

# kind delete cluster --name kind

IMAGE_NAME="jenkins-custom:latest"

docker build -t "${IMAGE_NAME}" . -f Dockerfile.jenkins

kind create cluster --config kubernetes/config.yaml

kind load docker-image "${IMAGE_NAME}"

kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml

sleep 10

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

kubectl apply -f jenkins/rbac.yaml

kubectl apply -f jenkins/deploy_jenkins.yaml

