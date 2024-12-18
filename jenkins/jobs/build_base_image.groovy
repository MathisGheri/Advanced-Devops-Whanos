folder('/Whanos base images') {
    description('Folder containing base image build jobs for Whanos.')
}

def languages = ['c', 'java', 'javascript', 'python', 'befunge']

languages.each { language ->
    freeStyleJob("/Whanos base images/whanos-${language}") {

        steps {
            shell("""
                cd /usr/share/jenkins/ref/images/${language}

                docker build -t whanos-${language}:latest - < Dockerfile.base
                docker tag whanos-${language}:latest potatgangcorp.fr:5000/whanos-${language}:latest
                docker push potatgangcorp.fr:5000/whanos-${language}:latest
            """.stripIndent())
        }
    }
}

freeStyleJob('/Whanos base images/Build all base images') {
    publishers {
        downstream(languages.collect { language -> "/Whanos base images/whanos-${language}" })
    }
}