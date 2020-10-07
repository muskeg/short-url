/* 
This pipeline is a GKE deployment PoC. It is fairly self-contained,
using a Docker agent to ensure the same environment between Jenkins agents.

It assumes you configured a few credentials, as described in the environment section
of the 'GKE Cluster Provisioning' stage:
- gpg-secret-key:               a secret file containing a GPG key for the decrypting of git-secret

- short-url-service-account:    a secret file containing the GCP service account .json
                                key file giving permissions to the project

- short-url-projectID:          a secret text representing the GCP project ID

- terraform-cli-config:         a secret file containing a .terraformrc CLI config file. It is
                                used to provide credentials for the backend.

*/
pipeline {
    agent none
    stages {
        stage('Clean up, pull and read environment variables') {
            /*
            This stage cleans the workspace so we start from scratch every time.
            Once cleaned up, we checkout the git repo.
            */
            agent {
                node {
                    label 'jenkins@muskegg'
                }
            }
            steps {
                    cleanWs()
                    checkout scm
            }
        }
        stage('GKE Cluster Provisioning') {
            /*
            This stage uses a small alpinelinux container to install and manage git-secret. 
            This allows Jenkins to reveal encrypted secrets in the SCM repositories.
            The container also installs Terraform and the Google Cloud SDK to provision the GKE cluster.
            */
            agent {
                docker {
                    image 'alpine:3.12'
                    args '-u root:root --network host -v ${PWD}:/usr/src/app -w /usr/src/app'
                }
            }
            environment {
                // Credentials used by the pipeline
                // GPG key for git-secret
                GPG_SECRET_KEY = credentials('gpg-secret-key')
                // GPC service account credentials
                GOOGLE_APPLICATION_CREDENTIALS = credentials('short-url-service-account')
                // The GCP project ID 
                SHORT_URL_PROJECTID = credentials('short-url-projectID')
                // The Terraform CLI config file
                TERRAFORM_RC = credentials('terraform-cli-config')
            }
            steps {

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
                gpg --batch --import $GPG_SECRET_KEY
                cd $WORKSPACE
                git secret reveal -f -p ''
                curl https://sdk.cloud.google.com | bash
                """

                /* 
                Terraform + GKE

                Using Jenkins's credentials to copy the credentials files to workspace folder.
                This allows connection to GCP and to the remote backend to ensure persistence of
                the terraform state between builds.
                */
                sh """
                cp $TERRAFORM_RC ~/.terraformrc
                cd $WORKSPACE/IaC/gke
                cp $GOOGLE_APPLICATION_CREDENTIALS service-account.json
                terraform init
                terraform apply -auto-approve
                """
            }
        }
    }
}