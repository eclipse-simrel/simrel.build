pipeline {
    agent any
    tools {
        jdk 'jdk11-latest'
        maven 'apache-maven-latest'
    }
    options {
        disableConcurrentBuilds()
        timeout(time: 3, unit: 'HOURS')
    }
    environment {
        TRAIN_NAME = "2021-03"
        STAGING_DIR = "/home/data/httpd/download.eclipse.org/staging/${TRAIN_NAME}"
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git branch: 'master',
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
                // https://bugs.eclipse.org/bugs/show_bug.cgi?id=370194 - add the name of the release on top of the repo reports main page
                sh "sed -i 's/<h1>Software Repository Reports<\\/h1>/<h1>Software Repository Reports - ${TRAIN_NAME}<\\/h1>/g' target/repository/final/buildInfo/reporeports/index.html"
                archiveArtifacts artifacts: 'target/repository/final/buildInfo/**/*', fingerprint: true, allowEmptyArchive: true
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
                // Create staging dir (if it does not exist already)
                sh 'mkdir -p ${STAGING_DIR}'
                // Clean staging dir
                sh 'rm -rf ${STAGING_DIR}/*'
                // Copying files to staging dir
                sh 'cp -R ${WORKSPACE}/target/repository/final/* ${STAGING_DIR}/'
                sh 'ls -al ${STAGING_DIR}'
                // Trigger EPP job
                sh 'curl https://ci.eclipse.org/packaging/job/simrel.epp-tycho-build/buildWithParameters?token=Yah6CohtYwO6b?6P'
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