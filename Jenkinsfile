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
        TRAIN_NAME = "2022-12"
        STAGING_DIR = "/home/data/httpd/download.eclipse.org/staging/${TRAIN_NAME}"
    }
    parameters {
      choice(
        name: 'CBI_TYPE',
        choices: ['nightly/latest', 'milestone/latest', 'release/latest'],
        description: '''
          Choose the type of CBI p2 Aggregator products build to use for aggregation, i.e., the relative path in the <a href="https://download.eclipse.org/cbi/updates/p2-aggregator/products/">products folder</a>.
          '''
      )
  
      booleanParam(
        name: 'PROMOTE',
        defaultValue: true,
        description: 'Whether to promote the build to the download server.'
      )
    }
 
    stages {
        stage('Initialize PGP') {
            steps {
                withCredentials([file(credentialsId: 'secret-subkeys.asc', variable: 'KEYRING')]) {
                 sh '''
                   gpg --batch --import "${KEYRING}"
                   for fpr in $(gpg --list-keys --with-colons  | awk -F: \'/fpr:/ {print $10}\' | sort -u); do echo -e "5\ny\n" |  gpg --batch --command-fd 0 --expert --edit-key ${fpr} trust; done
                   '''
                }
            }
        }
        stage('Build clean') {
            steps {
                withCredentials([string(credentialsId: 'gpg-passphrase', variable: 'KEYRING_PASSPHRASE')]) {
                    sh '''
                      mvn clean verify -Dgpg.passphrase="${KEYRING_PASSPHRASE}" -DPbuilt-at-eclipse.org -Pbuild -Pgpg-sign
                      mvn verify -Ppost-process-repository
                      '''
                }
                // archiveArtifacts 'target/repository/final/**'
            }
        }
        stage('Deploy to staging') {
            when {
              expression {
                params.PROMOTE
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
                sh 'curl "https://ci.eclipse.org/packaging/job/simrel.epp-tycho-build/buildWithParameters?delay=600sec&token=Yah6CohtYwO6b?6P"'
            }
        }
        stage('Start repository analysis') {
            when {
              expression {
                params.PROMOTE
              }
            }
            steps {
                build job: 'simrel.oomph.repository-analyzer.test',
                parameters: [
                    booleanParam(name: 'PROMOTE', value: true),
                    string(name: 'TRAIN_LOCATION', value: "staging/${env.TRAIN_NAME}")
                ], 
                wait: false
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
              to: 'ed.merks@eclipse-foundation.org'
            )
          archiveArtifacts artifacts: 'target/eclipserun-work/configuration/*.log', allowEmptyArchive: true
        }
    }
}
