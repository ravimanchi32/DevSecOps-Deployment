pipeline {
    agent any

    parameters {
        booleanParam(name: 'DESTROY_INFRA', defaultValue: false, description: 'Run terraform destroy after pipeline?')
    }

    environment {
        AWS_REGION   = "us-east-1"
        TF_WORKDIR   = "terraform"
        KUBECONFIG   = "$WORKSPACE/kubeconfig"
        CHART_NAME   = "my-nginx"
        CHART_PATH   = "./helm"
    }

    stages {

        stage("Setup Tools (Run Once)") {
            steps {
                sh '''
                # AWS CLI
                if ! command -v aws >/dev/null 2>&1; then
                    echo "Installing AWS CLI..."
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    sudo apt install -y unzip
                    sudo unzip awscliv2.zip
                    sudo ./aws/install
                else
                    echo "AWS CLI already installed."
                fi
                aws --version

                # kubectl
                if ! command -v kubectl >/dev/null 2>&1; then
                    echo "Installing kubectl..."
                    sudo curl --silent --location -o /usr/local/bin/kubectl \
                        https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
                    sudo chmod +x /usr/local/bin/kubectl
                else
                    echo "kubectl already installed."
                fi
                kubectl version --short --client

                # Terraform
                if ! command -v terraform >/dev/null 2>&1; then
                    echo "Installing Terraform..."
                    curl -LO https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
                    unzip terraform_1.9.0_linux_amd64.zip
                    sudo mv terraform /usr/local/bin/
                else
                    echo "Terraform already installed."
                fi
                terraform -version
                '''
            }
        }

        stage("Checkout Code") {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ravimanchi32/DevSecOps-Deployment.git'
            }
        }

        /* ----------------------------------------------
                AWS CREDENTIALS BLOCK (ONE TIME)
           ---------------------------------------------- */
        stage("Terraform & AWS Operations") {
            environment {
                AWS_SHARED_CREDENTIALS_FILE = "$WORKSPACE/.aws/credentials"
            }
            stages {

                stage("Configure AWS Credentials") {
                    steps {
                        withCredentials([
                            string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                            string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {

                            sh '''
                            mkdir -p $WORKSPACE/.aws

                            cat > $WORKSPACE/.aws/credentials <<EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
region=${AWS_REGION}
EOF

                            echo "AWS credentials configured once."
                            '''
                        }
                    }
                }

                stage('Terraform Init') {
                    steps {
                        dir("${TF_WORKDIR}") {
                            sh 'terraform init'
                        }
                    }
                }

                stage('Terraform Plan') {
                    steps {
                        dir("${TF_WORKDIR}") {
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                }

                stage('Terraform Apply (Run Once)') {
                    steps {
                        script {
                            def clusterExists = sh(
                                script: """
                                aws eks describe-cluster \
                                    --name $(terraform -chdir=${TF_WORKDIR} output -raw cluster_name) \
                                    --region ${AWS_REGION} >/dev/null 2>&1
                                """,
                                returnStatus: true
                            )

                            if (clusterExists == 0) {
                                echo "Cluster exists → Skipping terraform apply."
                            } else {
                                echo "Cluster NOT found → Running terraform apply..."
                                dir("${TF_WORKDIR}") {
                                    sh 'terraform apply -auto-approve tfplan'
                                }
                            }
                        }
                    }
                }

                stage("Update kubeconfig") {
                    steps {
                        sh '''
                        CLUSTER_NAME=$(terraform -chdir=${TF_WORKDIR} output -raw cluster_name)

                        aws eks update-kubeconfig \
                            --name $CLUSTER_NAME \
                            --region ${AWS_REGION} \
                            --kubeconfig ${KUBECONFIG}

                        echo "Kubeconfig created at ${KUBECONFIG}"
                        '''
                    }
                }
            }
        }

        /* -----------------------------
               HELM DEPLOYMENT
           ----------------------------- */
        stage("Deploy Helm Chart") {
            steps {
                sh '''
                echo "Checking Helm..."
                if ! command -v helm >/dev/null 2>&1; then
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                fi

                echo "Helm Version:"
                helm version

                echo "Helm Lint..."
                helm lint ${CHART_PATH}

                echo "Dry Run..."
                helm upgrade --install ${CHART_NAME} ${CHART_PATH} \
                    --kubeconfig ${KUBECONFIG} --dry-run --debug

                echo "Deploying Chart..."
                helm upgrade --install ${CHART_NAME} ${CHART_PATH} \
                    --kubeconfig ${KUBECONFIG}
                '''
            }
        }

        stage("Verify Deployment") {
            steps {
                sh '''
                kubectl --kubeconfig=${KUBECONFIG} get nodes
                kubectl --kubeconfig=${KUBECONFIG} get pods -A
                '''
            }
        }

        /* ----------------------------------------------
               OPTIONAL TERRAFORM DESTROY
           ---------------------------------------------- */
        stage("Terraform Destroy (Optional)") {
            when {
                expression { return params.DESTROY_INFRA == true }
            }
            steps {
                dir("${TF_WORKDIR}") {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }

    }

    post {
        success { echo "Pipeline completed successfully!" }
        failure { echo "Pipeline failed. Check logs." }
    }
}
