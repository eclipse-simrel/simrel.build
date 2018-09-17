pipeline {
    agent any
    tools {
        maven 'apache-maven-latest' 
    }
    environment {
        TRAIN_NAME = "2018-09"
        STAGING_DIR = "/home/data/httpd/download.eclipse.org/staging/${TRAIN_NAME}"
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git branch: '2018-09_respin',
                    url: 'git://git.eclipse.org/gitroot/simrel/org.eclipse.simrel.build'
            }
        }
        stage('Validate') {
            steps {
                sh 'mvn clean test -Pbuilt-at-eclipse.org -Pvalidate'
            }
        }
        stage('Build clean') {
            when {
                not {
                    environment name: 'gerrit',
                                value: 'true',
                                ignoreCase: true
                }
            }
            steps {
                sh 'mvn clean verify -Pbuilt-at-eclipse.org'
                archiveArtifacts artifacts: 'target/repository/final/buildInfo/**/*', fingerprint: true
            }
        }
        stage('Deploy to staging') {
            when {
                not {
                    environment name: 'gerrit',
                                value: 'true',
                                ignoreCase: true
                }
            }
            steps {
                // Cleaning staging dir
                sh 'rm -rf ${STAGING_DIR}/*'
                // Copying files to staging dir
                sh 'cp -R ${WORKSPACE}/target/repository/final/* ${STAGING_DIR}/'
                sh 'ls -al ${STAGING_DIR}'
                // Trigger EPP job
                sh 'curl https://ci.eclipse.org/packaging/job/simrel.epp-tycho-build/buildWithParameters?token=Yah6CohtYwO6b?6P'
            }
         }
    }
    post {
        failure {
          emailext (
              subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
              body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
                <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
              recipientProviders: [[$class: 'DevelopersRecipientProvider']],
              to: 'frederic.gurr@eclipse-foundation.org'
            )
        }
    }
}