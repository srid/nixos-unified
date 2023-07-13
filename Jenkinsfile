pipeline {
    agent any
    stages {
        stage ('NixCI') {
            steps {
                sh 'nix run github:srid/nixci'
            }
        }
        stage ('Tests') {
            steps {
                sh '''
                    pushd ./examples/both
                    ./test.sh && popd

                    pushd ./examples/linux
                    ./test.sh && popd

                    pushd ./examples/macos
                    ./test.sh && popd

                    pushd ./examples/home
                    ./test.sh && popd
                   '''
            }
        }
    }
}
