pipeline {
    agent any
    stages {
        stage ('Tests') {
            steps {
                sh '''
                    cd ./examples/both
                    ./test.sh
                   '''
            }
        }
    }
}
