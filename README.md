# Jenkins for Docker and Kubernetes

## Reference
- https://hub.docker.com/r/jenkins/jenkins
- https://github.com/jenkinsci/docker/blob/master/README.md


## Build the image
~~~
VERSION=$(cat version)
docker build -t 127.0.0.1:30500/internal/jenkins:$VERSION . --no-cache
~~~

## Docker deployment to the local workstation

~~~
# start the container
VERSION=$(cat version)
docker run --name jenkins -p 8080:8080 -p 50000:50000 -d 127.0.0.1:30500/internal/jenkins:$VERSION

# see the status
docker container ls

# open the url
open http://127.0.0.1:8080

# destroy the container
docker container stop jenkins
docker container rm jenkins

# save a copy of the image
docker save 127.0.0.1:30500/internal/jenkins:$VERSION > internal.jenkins-$VERSION.tar
~~~


https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2


Display the Jenkins admin password 
~~~
kubectl exec -it `kubectl get pods --selector=app=jenkins --output=jsonpath={.items..metadata.name}` cat /var/jenkins_home/secrets/initialAdminPassword
~~~

Click 'Install suggested plugins'


Login to the Jenkins pod
~~~
kubectl get pods --namespace=jenkins
kubectl exec -it --namespace=jenkins jenkins-859bd97b86-9fbwx /bin/bash
~~~

Create a kubeconfig file that will allow access to our Kubernetes cluster
~~~
kubectl config set-credentials jenkins --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kubectl config set-cluster kubernetes --server="https://kubernetes.default:443" --certificate-authority="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
kubectl config set-context jenkins-kubernetes --cluster=kubernetes.default --user=jenkins --namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
kubectl config use-context jenkins-kubernetes
chmod 755 ~/.kube/config
~~~

Verify the connection
~~~
kubectl cluster-info
~~~

Display the initial jenkins admin password
~~~
cat /var/jenkins_home/secrets/initialAdminPassword
~~~

http://localhost:8080/

Install the 'Kubernetes Continuous Deploy' plugin
Install the 'Job DSL' plugin


Install the Job DSL Plugin & "Use the provided DSL script"
~~~
def projects = ['rabbitmq']
projects.each {
	def projectName = it
	pipelineJob("${projectName}-pipeline") {
    	definition {
        	cpsScm {
            	scm {
                	github("stevenriggs/${projectName}", 'master', 'https')
            	}
        	}
    	}
	}  
}
~~~



## SSH keys for private GitHub repos
~~~
ssh-keygen -t rsa -C "Deploy key for kubernetes repo" -N '' -f ~/.ssh/github_deploykey_rsa
~~~

