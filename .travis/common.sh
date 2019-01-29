#!/usr/bin/env bash

COMPOSE_VER="1.22.0"
KUBECTL_VER="v1.13.0"
MINIKUBE_VER="v0.32.0"

docker_update() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
}

docker_compose_update() {
    local docker_compose_version=$COMPOSE_VER

    docker-compose --version
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
    docker-compose --version
    docker --version
}

# $1 tag
docker_push() {
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker push "$1"
}

kubectl_install() {
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VER/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
}

minikube_install() {
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VER/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
    sudo minikube start --vm-driver=none
    minikube update-context
    echo "Waiting for nodes:"
    kubectl get nodes
    #wait until nodes report as ready
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; \
    until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 1; done
    cp ~/.minikube/ca.crt ~/.kube/
    cp ~/.minikube/client.crt ~/.kube/
    cp ~/.minikube/client.key ~/.kube/
    cp ~/.kube/config ~/.kube/config_for_salt
    sed -i 's;/home/travis/.minikube/ca.crt;/etc/kubernetes/ca.crt;g' ~/.kube/config_for_salt
    sed -i 's;/home/travis/.minikube/client.crt;/etc/kubernetes/client.crt;g' ~/.kube/config_for_salt
    sed -i 's;/home/travis/.minikube/client.key;/etc/kubernetes/client.key;g' ~/.kube/config_for_salt
    echo "minikube setup complete"
}

still_running() {
    minutes=0
    limit=60
    while docker ps | grep -q $1; do
        echo -n -e " \b"
        if [ $minutes == $limit ]; then
            break;
        fi
        minutes=$((minutes+1))
        sleep 60
    done
}
