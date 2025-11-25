pipeline {
    agent any

    environment {
        TF_WORKDIR = "terraform"
        AWS_REGION = "ap-south-1"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/ravimanchi32/DevSecOps-Deployment.git'
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    mkdir -p ~/.aws

                    cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
EOF

                    cat > ~/.aws/config <<EOF
[default]
region=${AWS_REGION}
EOF
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

        stage('Terraform Apply') {
            steps {
                dir("${TF_WORKDIR}") {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Fetch EKS Cluster Name') {
            steps {
                script {
                    env.CLUSTER_NAME = sh(
                        script: "terraform -chdir=${TF_WORKDIR} output -raw cluster_name",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                sh """
                aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${CLUSTER_NAME}
                """
            }
        }

        stage('Kubernetes Status') {
            steps {
                sh """
                kubectl get nodes
                kubectl get pods -A
                kubectl get svc -A
                """
            }
        }

        stage('Helm Deploy NGINX') {
            steps {
                sh """
                helm upgrade --install my-nginx ./helm
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline completed."
        }
        failure {
            echo "Pipeline failed ❌"
        }
        success {
            echo "Pipeline succeeded ✅"
        }
    }
}
