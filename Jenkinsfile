pipeline {
  agent any

  tools {
    jdk 'temurin-jdk21-latest'
    maven 'apache-maven-latest'
  }

  options {
    disableConcurrentBuilds(abortPrevious: true)
    timeout(time: 3, unit: 'HOURS')
    timestamps ()
  }

  environment {
    TRAIN_NAME = "2025-12"
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
      defaultValue: true,
      description: 'Whether to PGP sign the repository contents.'
    )
  }

  stages {
    stage('Setup Environment') {
      steps {
        echo """
> Initial:
CBI_TYPE=${params.CBI_TYPE}
PROMOTE=${params.PROMOTE}
PGP_SIGN=${params.PGP_SIGN}
BRANCH_NAME=${env.BRANCH_NAME}
"""
        script {
          env.PGP_SIGN = params.PGP_SIGN
          env.CBI_TYPE = params.CBI_TYPE
          env.PROMOTE = params.PROMOTE
          env.PGP_MVN_ARGUMENTS = ''

          if (env.BRANCH_NAME == 'main') {
            if (params.PGP_SIGN) {
              env.PGP_MVN_ARGUMENTS = '-Pgpg-sign'
            }
          } else {
            env.PROMOTE = 'false'
          }
        }

        echo """
> Effective:
PROMOTE=${env.PROMOTE}
"""
      }
    }

    stage('Build clean') {
      steps {
        script {
          if (env.PROMOTE == 'true') {
            withCredentials([
              file(credentialsId: 'secret-subkeys.asc', variable: 'KEYRING'),
              string(credentialsId: 'gpg-passphrase', variable: 'MAVEN_GPG_PASSPHRASE')]) {
              sh '''
               java -version
               mvn \
                -Dtycho.pgp.signer="bc" \
                -Dtycho.pgp.signer.bc.secretKeys="${KEYRING}" \
                -Pbuild \
                ${PGP_MVN_ARGUMENTS} \
                clean \
                verify
               '''
            }
          } else {
            sh '''
             java -version
             mvn \
              -Pvalidate \
              -Pbuild \
              clean \
              test
             '''
          }
        }
      }
    }

    stage('Deploy to staging') {
      when {
       environment name: 'PROMOTE', value: 'true'
      }
      steps {
        sshagent(['projects-storage.eclipse.org-bot-ssh']) {
          script {
            lock('staging-repository') {
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
          }
        }

        // Trigger EPP job
        // Disabled until refactoring in https://github.com/eclipse-packaging/packages/issues/120 is complete
        // sh 'curl "https://ci.eclipse.org/packaging/job/simrel.epp-tycho-build/buildWithParameters?delay=600sec&token=Yah6CohtYwO6b?6P"'
      }
    }

    stage('Start repository analysis') {
      when {
       environment name: 'PROMOTE', value: 'true'
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
