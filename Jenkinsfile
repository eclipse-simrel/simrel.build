// The pom.xml can be modified and its contents can copied into pom variable below to test out a modified pom.xml before checking it in.
def pom = '''\
'''

pipeline {
    agent any 
    tools {
        jdk 'temurin-jdk17-latest'
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

      booleanParam(
        name: 'PGP_SIGN',
        defaultValue: false,
        description: 'Whether to PGP sign the repository contents.'
      )
    }

    stages {
        stage('Setup Environment') {
            steps {
                script {
                    env.PGP_SIGN = params.PGP_SIGN
                    env.CBI_TYPE = params.CBI_TYPE
                    env.PROMOTE = params.PROMOTE
                    env.PGP_MVN_ARGUMENTS = ''
                    if (params.PGP_SIGN) {
                        env.PGP_MVN_ARGUMENTS = '-Pgpg-sign'
                    }
                }
            }
        }
        stage('Git Checkout') {
           when {
             expression {
                // This stage is useful for testing changes to the pipeline.
                // The changes can be pasted into a pipeline job to test them before committing them.
               false
             }
          }
          steps {
            script {
              def gitVariables = checkout(
                poll: false,
                scm: [
                  $class: 'GitSCM',
                  branches: [[name: '*/master']],
                  doGenerateSubmoduleConfigurations: false,
                  submoduleCfg: [],
                  userRemoteConfigs: [[url: 'https://git.eclipse.org/r/simrel/org.eclipse.simrel.build.git']]
                ]
              )
              echo "$gitVariables"
              env.GIT_COMMIT = gitVariables.GIT_COMMIT
            }
          }
        }
        stage('Build clean') {
            steps {
                script {
                    if (pom.trim().length() > 0) {
                        writeFile file: 'pom.xml', text: pom
                    }
                }
                withCredentials([
                    file(credentialsId: 'secret-subkeys.asc', variable: 'KEYRING'),
                    string(credentialsId: 'gpg-passphrase', variable: 'KEYRING_PASSPHRASE')]) {
                    sh '''
                      java -version
                      mvn \
                        -Dtycho.pgp.signer="bc" \
                        -Dtycho.pgp.signer.bc.secretKeys="${KEYRING}" \
                        -Dgpg.passphrase="${KEYRING_PASSPHRASE}" \
                        -Pbuild \
                        ${PGP_MVN_ARGUMENTS} \
                        clean \
                        verify
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
                sshagent(['projects-storage.eclipse.org-bot-ssh']) {
                    sh '''
                        ssh genie.simrel@projects-storage.eclipse.org "
                            mkdir -p ${STAGING_DIR}
                            rm -rf ${STAGING_DIR}/*
                        "
                        scp -r ${WORKSPACE}/target/repository/final/* genie.simrel@projects-storage.eclipse.org:${STAGING_DIR}/
                        ssh genie.simrel@projects-storage.eclipse.org "
                            ls -sail ${STAGING_DIR}
                        "
                    '''
                }
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
