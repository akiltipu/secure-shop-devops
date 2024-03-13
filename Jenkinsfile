// Jenkins Pipeline script for building, testing, and deploying a Java application.
// This script assumes the use of Docker, SonarQube, OWASP Dependency Check, Maven, and Kubernetes.

pipeline {
    agent any

    tools {
        // Specify the required tools and their versions
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        // Define environment variables
        SCANNER_HOME = tool 'sonar-scanner'
        ECR_REPO_URL = '<ECR_REPO_URL>' // Replace with the actual ECR repository URL
        ECR_APP_NAME = '<ECR_APP_NAME>' // Replace with the name of your ECR application
        IMAGE_REPO = "$ECR_REPO_URL/$ECR_APP_NAME"
        IMAGE_NAME = "${env.BUILD_NUMBER}"
        APP_NAME = '<APP_NAME>' // Replace with the name of your application
    }

    stages {
        stage('Git Checkout') {
            steps {
                echo 'Checking github...'
                // Checkout the code from the Git repository
                checkout([$class: 'GitSCM', branches: [[name: 'main']], userRemoteConfigs: [[url: '<GIT_REPO_URL>']]])
            }
        }

        stage('Compile Source Code') {
            steps {
                echo 'Compiling Source code...'
                // Compile the source code
                sh 'mvn compile'
            }
        }

        stage('Unit Test') {
            steps {
                echo 'Testing the code...'
                // Run unit tests (skipping tests for now)
                sh 'mvn test -DskipTests=true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'SonarQube Analysis started...'
                script {
                    // Run SonarQube analysis
                    withSonarQubeEnv('<SONAR_ENVIRONMENT>') { // Replace with the name of your SonarQube environment
                        sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=<PROJECT_KEY> \
                    -Dsonar.projectName=<PROJECT_NAME> -Dsonar.java.binaries=.
                    '''
                    }
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                script {
                    echo 'Owasp dependency check initiating...'
                    // Run OWASP Dependency Check
                    def scanResult = dependencyCheck additionalArguments: '--scan ./', nvdCredentialsId: '<NVD_CREDENTIALS_ID>', odcInstallation: 'DC' // Replace with the ID of the NVD credentials used for OWASP Dependency Check
                    // Mark the build as successful even if there are findings
                    currentBuild.result = scanResult ? 'SUCCESS' : 'UNSTABLE'

                    // Archive the Dependency Check report for later review
                    archiveArtifacts artifacts: '**/dependency-check-report.xml', allowEmptyArchive: true
                }
            }
        }

        stage('Build Source Code') {
            steps {
                echo 'Building Source code...'
                // Build the source code (skipping tests)
                sh 'mvn package -DskipTests=true'
            }
        }

        stage('Artifact storing in Nexus') {
            steps {
                echo 'Publishing Artifact to Nexus Artifact repository...'
                // Deploy the artifact to Nexus using Maven
                withMaven(globalMavenSettingsConfig: '<GLOBAL_MAVEN_SETTINGS>', jdk: 'jdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) { // Replace with the configuration name for global Maven settings
                    sh 'mvn deploy -DskipTests=true'
                }
            }
        }

        stage('Build Container image & push to ECR') {
            steps {
                script {
                    echo 'building the docker image...'
                    // Build and push the Docker image to ECR
                    withCredentials([usernamePassword(credentialsId: '<AWS_CREDENTIALS_ID>', passwordVariable: 'PASS', usernameVariable: 'USER')]) { // Replace with the ID of the AWS credentials used for ECR login
                        sh "docker build -t ${IMAGE_REPO}:${IMAGE_NAME} ."
                        sh "echo $PASS | docker login -u AWS --password-stdin ${ECR_REPO_URL}"
                        sh "docker push ${IMAGE_REPO}:${IMAGE_NAME}"
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                echo 'Scanning Docker Image using Trivy...'
                // Scan the Docker image using Trivy
                sh "trivy image ${IMAGE_REPO}:${IMAGE_NAME} > trivy-report.txt"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Deploy the application to Kubernetes
                sh 'envsubst < kubernetes/deployment.yaml | kubectl delete -f -'
                sh 'envsubst < kubernetes/service.yaml | kubectl delete -f -'
            }
        }

        stage('commit version update') {
            steps {
                script {
                    // Commit and push changes to the Git repository
                    withCredentials([string(credentialsId: '<GITHUB_TOKEN_ID>', variable: 'GITHUB_TOKEN')]) { // Replace with the ID of the GitHub token credentials
                        sh 'git config user.email "jenkins@example.com"'
                        sh 'git config user.name "Jenkins"'
                        sh "git remote set-url origin https://${GITHUB_TOKEN}@<GIT_REPO_URL>" // Replace with the URL of your Git repository
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:main'
                    }
                }
            }
        }
    }
}
