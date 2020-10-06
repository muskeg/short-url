pipeline {
    agent none
    stages {
        stage('Clean up') {
            /*
            This stage cleans the workspace so we start from scratch every time
            */
            agent {
                    node {
                            label 'jenkins@muskegg'
                    }
            }
            steps {
                    cleanWs()
            }
        }
        stage('GKE Cluster Provisioning') {
            /*
            This stage uses a small alpinelinux container to install and manage git-secret. 
            This allows Jenkins to reveal encrypted secrets in the SCM repositories.
            The container also installs Terraform and the Google Cloud SDK
            to provision the GKE cluster.
            */
            agent {
                docker {
                    image 'alpine:3.12'
                    args '-u root:root --network host -v ${PWD}:/usr/src/app -w /usr/src/app'
                }
            }
            environment {
                GPG_SECRET_KEY = credentials('gpg-secret-key')
                GOOGLE_APPLICATION_CREDENTIALS = credentials('short-url-service-account')
            }
            steps {
                checkout scm

                // Prepare the container for GKE provisioning
                sh """
                echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories
                echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories
                echo "http://nl.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
                echo "http://nl.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories
                echo "http://nl.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories
                apk update
                apk add gawk git git-secret terraform python3 curl bash
                ln -sf python3 /usr/bin/python
                python3 -m ensurepip
                pip3 install --no-cache --upgrade pip setuptools
                gpg --batch --import $GPG_SECRET_KEY
                cd $WORKSPACE
                #git secret reveal -f -p ''
                curl https://sdk.cloud.google.com | bash
                """

                // Configure GCloud and export application credentials for Terraform to use
                sh """
                /root/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                /root/google-cloud-sdk/bin/gcloud config set project short-url-291201
                """

                // Terraform + GKE
                sh """
                cd $WORKSPACE/IaC/
                terraform init
                terraform plan gke
                """
            }
        }
    }
}