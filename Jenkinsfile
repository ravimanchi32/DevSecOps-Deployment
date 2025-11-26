pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'DESTROY_INFRA',
            defaultValue: false,
            description: 'Run terraform destroy only?'
        )
    }

    environment {
        TF_WORKDIR = "terraform"
        AWS_REGION = "ap-south-1"
    }

    stages {

        /******************** NORMAL PIPELINE (WHEN DESTROY_INFRA = false) ********************/
        stage('Checkout') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                git branch: 'main', url: 'https://github.com/ravimanchi32/DevSecOps-Deployment.git'
            }
        }

        stage('Setup Script Permissions') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh "chmod +x install-dependencies.sh"
            }
        }

        stage('Run Dependency Installation Script') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh "./install-dependencies.sh"
            }
        }

        stage('Configure AWS Credentials') {
            when { expression { !params.DESTROY_INFRA } }
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
            when { expression { !params.DESTROY_INFRA } }
            steps {
                dir("${TF_WORKDIR}") {
                    sh "terraform init"
                }
            }
        }

        stage('Terraform Plan') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                dir("${TF_WORKDIR}") {
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                dir("${TF_WORKDIR}") {
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }

        stage('Fetch EKS Cluster Name') {
            when { expression { !params.DESTROY_INFRA } }
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
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh """
                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${CLUSTER_NAME}
                """
            }
        }

        stage('Kubernetes Status') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh """
                    kubectl get nodes
                    kubectl get pods -A
                    kubectl get svc -A
                """
            }
        }

        stage('Deploy Application') {
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh "helm upgrade --install custom-app ./helm --force"
            }
        }

        stage('Deploy Prometheus & Grafana') {
            when { expression { !params.DESTROY_INFRA } }
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
            when { expression { !params.DESTROY_INFRA } }
            steps {
                sh "kubectl get svc -n monitoring"
            }
        }

        /******************** DESTROY PIPELINE (WHEN DESTROY_INFRA = true) ********************/
        stage("Terraform Destroy") {
            when { expression { params.DESTROY_INFRA } }
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
    }
}
