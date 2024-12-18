#!/bin/bash

DISPLAY_NAME=$1
# Détection du langage
if [ -f Makefile ]; then
    LANG="c"
elif [ -f app/pom.xml ]; then
    LANG="java"
elif [ -f package.json ]; then
    LANG="javascript"
elif [ -f requirements.txt ]; then
    LANG="python"
elif [ -f app/main.bf ]; then
    LANG="befunge"
else
    echo "No supported language detected"
    exit 1
fi

echo "Detected language: $LANG"

if [ -f Dockerfile ]; then
    echo "Using image: whanos-project-${DISPLAY_NAME}"
    docker build -t whanos-project-${DISPLAY_NAME}:latest .
else
    echo "Using standalone image: whanos-project-${DISPLAY_NAME}"
    docker build -t whanos-project-${DISPLAY_NAME}:latest -f /usr/share/jenkins/ref/images/${LANG}/Dockerfile.standalone .
fi

docker tag whanos-project-${DISPLAY_NAME}:latest potatgangcorp.fr:5000/whanos-project-${DISPLAY_NAME}:latest
docker push potatgangcorp.fr:5000/whanos-project-${DISPLAY_NAME}:latest

if [ -f whanos.yml ]; then
    if grep -q "deployment:" whanos.yml; then
        REPLICAS=$(yq e '.deployment.replicas' whanos.yml || echo 1)
        PORTS=$(yq e '.deployment.ports[]' whanos.yml || true)
        LIMITS_MEMORY=$(yq e '.deployment.resources.limits.memory' whanos.yml || echo "")
        REQUESTS_MEMORY=$(yq e '.deployment.resources.requests.memory' whanos.yml || echo "")

cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DISPLAY_NAME}-app
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${DISPLAY_NAME}-app
  template:
    metadata:
      labels:
        app: ${DISPLAY_NAME}-app
    spec:
      containers:
      - name: app
        image: potatgangcorp.fr:5000/whanos-project-${DISPLAY_NAME}:latest
        ports:
          $(for p in $PORTS; do echo "- containerPort: $p"; done)
        resources:
          limits:
            memory: "${LIMITS_MEMORY}"
          requests:
            memory: "${REQUESTS_MEMORY}"
---
kind: Service
apiVersion: v1
metadata:
  name: ${DISPLAY_NAME}-service
spec:
  selector:
    app: ${DISPLAY_NAME}-app
  ports:
    $(for p in $PORTS; do echo "- port: $p"; done)
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${DISPLAY_NAME}-ingress
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: /${DISPLAY_NAME}
        backend:
          service:
            name: ${DISPLAY_NAME}-service
            port:
              number: $(for p in $PORTS; do echo "$p"; done)
EOF

        cat deployment.yaml

        kubectl apply -f deployment.yaml
    else
        echo "whanos.yml present but no deployment section"
    fi
else
    echo "No whanos.yml found, no deployment needed."
fi