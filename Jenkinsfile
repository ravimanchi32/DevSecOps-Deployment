pipeline {
    agent any

    parameters {
        booleanParam(name: 'DESTROY_INFRA', defaultValue: false, description: 'Run terraform destroy?')
    }

    environment {
        AWS_REGION = "us-east-1"
        TF_WORKDIR = "terraform"
        KUBECONFIG = "$WORKSPACE/kubeconfig"
        CHART_NAME = "my-nginx"
        CHART_PATH = "./helm"
    }

    stages {

        stage('Setup Tools (Run Once)') {
            steps {
                sh '''
                # --- AWS CLI ---
                if ! command -v aws >/dev/null 2>&1; then
                  echo "Installing AWS CLI..."
                  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                  sudo apt install -y unzip
                  sudo unzip awscliv2.zip
                  sudo ./aws/install
                else
                  echo "AWS CLI already installed. Skipping."
                fi
                aws --version

                # --- kubectl ---
                if ! command -v kubectl >/dev/null 2>&1; then
                  echo "Installing kubectl..."
                  sudo curl --silent --location -o /usr/local/bin/kubectl \
                    https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
                  sudo chmod +x /usr/local/bin/kubectl
                else
                  echo "kubectl already installed. Skipping."
                fi
                kubectl version --short --client

                # --- Terraform ---
                if ! command -v terraform >/dev/null 2>&1; then
                  echo "Installing Terraform..."
                  curl -LO https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
                  unzip terraform_1.9.0_linux_amd64.zip
                  sudo mv terraform /usr/local/bin/
                else
                  echo "Terraform already installed. Skipping."
                fi
                terraform -version
                '''
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ravimanchi32/DevSecOps-Deployment.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                sudo apt-get update -y
                sudo apt-get install -y unzip curl jq
                '''
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
                        echo "EKS cluster already exists. Skipping terraform apply."
                    } else {
                        echo "EKS cluster NOT found. Running terraform apply..."
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
                AWS_CLUSTER_NAME=$(terraform -chdir=${TF_WORKDIR} output -raw cluster_name)

                aws eks update-kubeconfig \
                    --name $AWS_CLUSTER_NAME \
                    --region ${AWS_REGION} \
                    --kubeconfig ${KUBECONFIG}

                echo "Kubeconfig file created at ${KUBECONFIG}"
                '''
            }
        }

        stage("Deploy Helm Charts") {
            steps {
                sh '''
                echo "Checking Helm installation..."
                if ! command -v helm >/dev/null 2>&1; then
                    echo "Helm not found. Installing..."
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                else
                    echo "Helm already installed."
                fi

                echo "Helm Version:"
                helm version

                echo "Running Helm Lint..."
                helm lint ${CHART_PATH}

                echo "Helm Dry Run..."
                helm upgrade --install ${CHART_NAME} ${CHART_PATH} \
                    --kubeconfig ${KUBECONFIG} \
                    --dry-run --debug

                echo "Deploying Helm Release..."
                helm upgrade --install ${CHART_NAME} ${CHART_PATH} \
                    --kubeconfig ${KUBECONFIG}

                echo "Helm Deployment Completed."
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

        stage('Terraform Destroy (Optional)') {
            when {
                expression { params.DESTROY_INFRA == true }
            }
            steps {
                dir("${TF_WORKDIR}") {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        success { echo "Pipeline executed successfully." }
        failure { echo "Pipeline failed. Please check console output." }
    }
}
