pipeline {
    agent {
        node {
            label 'promotion-vm'
        }
    }
    tools {
        jdk 'openjdk-jdk11-latest'
        maven 'apache-maven-latest'
    }
    options {
        disableConcurrentBuilds()
        timeout(time: 3, unit: 'HOURS')
        timestamps ()
    }
    environment {
        TRAIN_NAME = "2021-12"
        STAGING_DIR = "/home/data/httpd/download.eclipse.org/staging/${TRAIN_NAME}"
    }
    stages {
        stage('Validate') {
            steps {
                sh 'mvn clean test -Pbuilt-at-eclipse.org -Pvalidate'
            }
        }
        stage('Build clean') {
            steps {
                sh 'mvn clean verify -Pbuilt-at-eclipse.org -Pbuild'
            }
        }
        stage('Deploy to staging') {
            steps {
                // Create staging dir (if it does not exist already)
                sh 'mkdir -p ${STAGING_DIR}'
                // Clean staging dir
                sh 'rm -rf ${STAGING_DIR}/*'
                // Copying files to staging dir
                sh 'cp -R ${WORKSPACE}/target/repository/final/* ${STAGING_DIR}/'
                sh 'ls -al ${STAGING_DIR}'
                // Trigger EPP job
                sh 'curl "https://ci.eclipse.org/packaging/job/simrel.epp-tycho-build/buildWithParameters?delay=600sec&token=Yah6CohtYwO6b?6P"'
            }
         }
         stage('Start repository analysis') {
            steps {
                build job: 'simrel.oomph.repository-analyzer.test', parameters: [booleanParam(name: 'PROMOTE', value: true)], wait: false
            }
         }
    }
    post {
        failure {
          emailext (
              subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
              body: """FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':
              Check console output at ${env.BUILD_URL}""",
              recipientProviders: [[$class: 'DevelopersRecipientProvider']],
              to: 'frederic.gurr@eclipse-foundation.org'
            )
          archiveArtifacts artifacts: 'target/eclipserun-work/configuration/*.log', allowEmptyArchive: true
        }
    }
}
