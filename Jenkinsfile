pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        LAUNCH_TEMPLATE_ID = 'lt-05ce0127e76f07ca5'
        PACKER_PATH = '/usr/local/bin/packer'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build AMI with Packer') {
            steps {
                sh '''
                    ${PACKER_PATH} validate packer.pkr.hcl
                    ${PACKER_PATH} build -force packer.pkr.hcl > packer.log
                '''
            }
        }

        stage('Parse AMI ID') {
            steps {
                script {
                    def log = readFile('packer.log')
                    def matcher = log =~ /AMI: (ami-[a-z0-9]+)/
                    if (matcher.find()) {
                        env.NEW_AMI_ID = matcher.group(1)
                        echo "New AMI ID: ${env.NEW_AMI_ID}"
                    } else {
                        error "AMI ID not found in Packer output!"
                    }
                }
            }
        }

        stage('Update Launch Template') {
            steps {
                sh '''
                    aws ec2 create-launch-template-version                         --launch-template-id ${LAUNCH_TEMPLATE_ID}                         --version-description "Updated with AMI ${NEW_AMI_ID}"                         --source-version 1                         --launch-template-data '{"ImageId":"${NEW_AMI_ID}"}'                         --region ${AWS_REGION}
                '''
            }
        }
    }
}
