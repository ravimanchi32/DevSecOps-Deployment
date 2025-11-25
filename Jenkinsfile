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

        stage('Deploy Application') {
            steps {
                sh """
                helm upgrade --install custom-app ./helm
                """
            }
        }

        stage('Deploy Prometheus & Grafana') {
            steps {
                sh """
                helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                helm repo update

                helm upgrade --install prom-stack prometheus-community/kube-prometheus-stack \
                    -n monitoring --create-namespace \
                    -f helm/prom-values.yaml
                """
            }
        }

        stage('Show Monitoring Services') {
            steps {
                sh "kubectl get svc -n monitoring"
            }
        }

        // ---- OPTIONAL DESTROY STAGE ----
        stage('Terraform Destroy') {
            when {
                expression {
                    return params.DESTROY_RESOURCES == true
                }
            }
            steps {
                dir("${TF_WORKDIR}") {
                    sh "terraform destroy -auto-approve"
                }
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
