pipeline {
    agent any
    stages {
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
