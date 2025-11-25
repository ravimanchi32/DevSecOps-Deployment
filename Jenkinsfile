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
        PATH         = "$HOME/bin:$PATH"
    }

    stages {

        stage("Setup Tools (Run Once)") {
            steps {
                sh '''
                mkdir -p $HOME/bin

                # --------------------
                # AWS CLI
                # --------------------
                if ! command -v aws >/dev/null 2>&1; then
                    echo "Installing AWS CLI..."
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip -o awscliv2.zip
                    ./aws/install -i $HOME/aws-cli -b $HOME/bin
                else
                    echo "AWS CLI already installed."
                fi
                aws --version

                # --------------------
                # kubectl
                # --------------------
                if ! command -v kubectl >/dev/null 2>&1; then
                    echo "Installing kubectl..."
                    curl -Lo $HOME/bin/kubectl \
                        https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
                    chmod +x $HOME/bin/kubectl
                else
                    echo "kubectl already installed."
                fi
                kubectl version --client --short

                # --------------------
                # Terraform
                # --------------------
                if ! command -v terraform >/dev/null 2>&1; then
                    echo "Installing Terraform..."
                    curl -LO https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
                    unzip -o terraform_1.9.0_linux_amd64.zip
                    mv terraform $HOME/bin/
                else
                    echo "Terraform already installed."
                fi
                terraform -version

                # --------------------
                # Helm
                # --------------------
                if ! command -v helm >/dev/null 2>&1; then
                    echo "Installing Helm..."
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                else
                    echo "Helm already installed."
                fi
                helm version
                '''
            }
        }

        stage("Checkout Code") {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ravimanchi32/DevSecOps-Deployment.git'
            }
        }

        stage("Configure AWS Credentials") {
            environment {
                AWS_SHARED_CREDENTIALS_FILE = "$WORKSPACE/.aws/credentials"
            }
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

                    echo "AWS credentials configured."
                    '''
                }
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir("${TF_WORKDIR}") {
                    sh 'terraform init'
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply (Run Once)') {
            steps {
                script {
                    // Get cluster name from Terraform output
                    def clusterName = sh(
                        script: "terraform -chdir=${TF_WORKDIR} output -raw cluster_name",
                        returnStdout: true
                    ).trim()

                    // Check if cluster exists
                    def clusterExists = sh(
                        script: "aws eks describe-cluster --name ${clusterName} --region ${AWS_REGION} >/dev/null 2>&1",
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
                script {
                    def clusterName = sh(
                        script: "terraform -chdir=${TF_WORKDIR} output -raw cluster_name",
                        returnStdout: true
                    ).trim()

                    sh """
                    aws eks update-kubeconfig --name ${clusterName} --region ${AWS_REGION} --kubeconfig ${KUBECONFIG}
                    echo "Kubeconfig created at ${KUBECONFIG}"
                    """
                }
            }
        }

        stage("Deploy Helm Chart") {
            steps {
                sh """
                helm lint ${CHART_PATH}

                echo "Dry run Helm upgrade/install..."
                helm upgrade --install ${CHART_NAME} ${CHART_PATH} \\
                    --kubeconfig ${KUBECONFIG} --dry-run --debug

                echo "Deploying Helm Chart..."
                helm upgrade --install ${CHART_NAME} ${CHART_PATH} \\
                    --kubeconfig ${KUBECONFIG}
                """
            }
        }

        stage("Verify Deployment") {
            steps {
                sh """
                kubectl --kubeconfig=${KUBECONFIG} get nodes
                kubectl --kubeconfig=${KUBECONFIG} get pods -A
                """
            }
        }

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
