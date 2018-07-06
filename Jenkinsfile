pipeline {
    agent any
    tools {
        maven 'apache-maven-latest' 
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git branch: 'master', url: 'git://git.eclipse.org/gitroot/simrel/org.eclipse.simrel.build'
            }
        }
        stage('Validate') {
            steps {
                sh 'mvn clean test -Pbuilt-at-eclipse.org -Pvalidate'
            }
        }
        stage('Build clean') {
            steps {
                sh 'mvn clean test -Pbuilt-at-eclipse.org'
            }
        }
    }
}