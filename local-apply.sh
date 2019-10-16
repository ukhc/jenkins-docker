# Copyright (c) 2019, UK HealthCare (https://ukhealthcare.uky.edu) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################

echo "validate positional parameters..."

if [ "$1" == "--with-volumes" ] || [ "$1" == "--without-volumes" ]
then
	DEPLOY_MODE="$1"
else
    echo "ERROR: Deploy mode is not valid.  Must be one of the following --with-volumes --without-volumes"
	exit 1
fi

##########################

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

echo "check for the jenkins docker image..."

VERSION=$(cat version)
docker images -q internal/jenkins:$VERSION
if [[ "$(docker images -q internal/jenkins:$VERSION 2> /dev/null)" == "" ]]; then
	echo "jenkins docker image not found, building now..."
	docker build -t internal/jenkins:$VERSION . --no-cache
	# check for successful build
	docker images -q internal/jenkins:$VERSION
	if [[ "$(docker images -q internal/jenkins:$VERSION 2> /dev/null)" == "" ]]; then
		echo "ERROR: jenkins docker image build failed... Exit script!"
		exit 1
	fi
else
	echo "jenkins docker image found..."
fi

##########################

echo "setup the persistent volume for jenkins...."
mkdir -p /Users/Shared/Kubernetes/persistent-volumes/default/jenkins
kubectl apply -f ./kubernetes/jenkins-local-pv.yaml

##########################

echo "deploy jenkins..."
rm -f yaml.tmp
cp ./kubernetes/jenkins.yaml yaml.tmp

#### Use the '--with-volumes' parameter to turn on the volume mounts ####
if [ "$DEPLOY_MODE" == "--with-volumes" ]
then
    echo "--with-volumes parameter was used, turning on the persistent volumes..."
    sed -i '' 's/#jenkins-persistent-storage#//' yaml.tmp
else
    echo "--without-volumes parameter was used, persistent volumes are off..."
fi

kubectl apply -f yaml.tmp
rm -f yaml.tmp

echo "wait for jenkins..."
sleep 2
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=jenkins -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for jenkins pod. Exit script!"
			exit 1
		else
			echo "waiting...jenkins pod is not ready...($isPodReadyCount/100)"
			sleep 2
		fi
	fi
done

##########################
kubectl get pods
echo
echo "opening the browser..."
open http://127.0.0.1:8080

##########################

echo "...done"