pipeline {
    agent any
    stages {
        stage ('NixCI') {
            steps {
                sh 'nix run --refresh github:srid/nixci'
            }
        }
    }
}
