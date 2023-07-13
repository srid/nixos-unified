pipeline {
    agent any
    stages {
        stage ('NixCI') {
            steps {
                // TODO: Upstream https://github.com/juspay/jenkins-nix-ci/issues/29
                sh 'nixci'
            }
        }
    }
}
