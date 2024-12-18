folder('/Projects') {
    description('Projects linked by the link-project job')
}

freeStyleJob('/link-project') {
    parameters{
        stringParam('GIT_URL', null, 'Git URL')
        stringParam('DISPLAY_NAME', null, 'Display Name')
        credentialsParam('CREDENTIAL') {
            type('com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey')
            description('SSH key to clone repository')
        }
    }
    steps {
        dsl('''
            freeStyleJob("/Projects/$DISPLAY_NAME") {
                scm {
                    git {
                        remote {
                            name('origin')
                            url("$GIT_URL")
                            credentials("$CREDENTIAL")
                        }
                        branches('*/main')
                    }
                }
                triggers {
                    scm('H/1 * * * *')
                }
                wrappers {
                    preBuildCleanup()
                }
                steps {
                    shell(\"/usr/share/jenkins/ref/whanos_deploy.sh $DISPLAY_NAME\")
                }
            }'''
        .stripIndent())
    }
}