#!/usr/bin/env groovy

def is_authorized(name) {
  def authorized_user = ['Rhett-Ying']
  return (name in authorized_user)
}

pipeline {
  agent any
  triggers {
        issueCommentTrigger('@dgl-bot .*')
  }
  stages {
    stage('CI Authorization ~ NonIssueComment') {
      agent {
        docker {
            label 'linux-benchmark-node'
            image 'dgllib/dgl-ci-lint'
            alwaysPull true
        }
      }
      when { not { triggeredBy 'IssueCommentCause' } }
      steps {
        script {
          def author = env.CHANGE_AUTHOR
          echo("author: ${env.CHANGE_AUTHOR}")
          if (author && !is_authorized(author)) {
            error("Not authorized to trigger CI. Please ask core developer to help trigger via issuing comment: \n - `@dgl-bot CI`")
          }
        }
      }
    }
    stage('CI Authorization ~ IssueComment') {
      agent {
        docker {
            label 'linux-benchmark-node'
            image 'dgllib/dgl-ci-lint'
            alwaysPull true
        }
      }
      when { triggeredBy 'IssueCommentCause' }
      steps {
        script {
          def comment = env.GITHUB_COMMENT
          def author = env.GITHUB_COMMENT_AUTHOR
          if (!is_authorized(author)) {
            error("Not authorized to trigger CI via issuing comment.")
          }
        }
      }
    }
    stage('CI') {
      stages {
        stage('Unit Test') {
          agent {
            docker {
              label "linux-cpu-node"
              image "dgllib/dgl-ci-lint"
              alwaysPull false
            }
          }
          steps {
            sh 'bash task_unit_test.sh'
          }
          post {
            always {
              cleanWs disableDeferredWipeout: true, deleteDirs: true
            }
          }
        }
      }
    }
  }
  post {
    always {
      script {
        node("dglci-post-linux") {
          docker.image('dgllib/dgl-ci-awscli:v220418').inside("--pull always --entrypoint=''") {
            sh("rm -rf ci_tmp")
            dir('ci_tmp') {
              sh("curl -k -o cireport.log ${BUILD_URL}consoleText")
              sh("curl -k -L ${BUILD_URL}wfapi")
              sh("curl -o report.py https://raw.githubusercontent.com/Rhett-Ying/dgl_test_script/main/report.py")
              sh("curl -o status.py https://raw.githubusercontent.com/Rhett-Ying/dgl_test_script/main/status.py")
              sh("cat status.py")
              sh("pytest --html=report.html --self-contained-html report.py || true")
              sh("aws s3 sync ./ s3://dgl-ci-result/${JOB_NAME}/${BUILD_NUMBER}/${BUILD_ID}/logs/  --exclude '*' --include '*.log' --acl public-read --content-type text/plain")
              sh("aws s3 sync ./ s3://dgl-ci-result/${JOB_NAME}/${BUILD_NUMBER}/${BUILD_ID}/logs/  --exclude '*.log' --acl public-read")

              def comment = sh(returnStdout: true, script: "python3 status.py").trim()
              echo(comment)
              if ((env.BRANCH_NAME).startsWith('PR-')) {
                pullRequest.comment(comment)
              }
            }
          }
        }
      }
    }
  }
}
