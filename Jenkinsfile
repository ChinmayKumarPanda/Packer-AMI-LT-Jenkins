pipeline {
    agent any
// veera
    environment {
        AWS_REGION = 'ap-south-1'
        LAUNCH_TEMPLATE_ID = 'lt-08ddc580a98ce478e'
        ASG_NAME = "packerasg"
        
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
          stage('Packer Init') {
            steps {
                sh 'packer init .'
            }
        }


        stage('Build AMI with Packer') {
            steps {
                // Save output to packer.log####veera
                sh '''
                   packer validate packer.pkr.hcl
                   packer build packer.pkr.hcl | tee packer.log
                '''
            }
        }

        stage('Parse AMI ID') {
            steps {
                script {
                    def log = readFile('packer.log')
                    def matcher = log =~ /AMI:(ami-[0-9a-f]+)/
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
            script {
              sh """
                aws ec2 create-launch-template-version \\
                  --launch-template-id ${LAUNCH_TEMPLATE_ID} \\
                  --version-description "Updated with AMI ${NEW_AMI_ID}" \\
                  --source-version 1 \\
                  --launch-template-data '{"ImageId":"${NEW_AMI_ID}"}' \\
                  --region ${AWS_REGION}
              """
            }
          }
        }
    
        stage('Start ASG Instance Refresh') {
          steps {
            script {
              sh """
                aws autoscaling start-instance-refresh \\
                  --auto-scaling-group-name ${ASG_NAME} \\
                  --preferences MinHealthyPercentage=50,InstanceWarmup=300 \\
                  --region ${AWS_REGION} \\
                  --query 'InstanceRefreshId' --output text
              """
            }
          }
        }
      }
    }
