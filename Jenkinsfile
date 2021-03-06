#!/usr/bin/env groovy

// Used Jenkins plugins:
// * Pipeline GitHub Notify Step Plugin
// * Disable GitHub Multibranch Status Plugin - https://github.com/bluesliverx/disable-github-multibranch-status-plugin
//
// $OCP_HOSTNAME -- hostname of running Openshift cluster
// $OCP_USER     -- Openshift user
// $OCP_PASSWORD -- Openshift user's password

node {
	withEnv(["GOPATH=$WORKSPACE", "KUBECONFIG=$WORKSPACE/client/kubeconfig", "PATH+OC_PATH=$WORKSPACE/client", "API_HOST=$OCP_HOSTNAME"]) {

		// generate build url
		def buildUrl = sh(script: 'curl https://url.corp.redhat.com/new?$BUILD_URL', returnStdout: true)

		stage('Build') {

			githubNotify(context: 'jenkins-ci/oshinko-cli', description: 'This change is being built', status: 'PENDING', targetUrl: buildUrl)

			try {
				// wipeout workspace
				deleteDir()

				dir('src/github.com/radanalyticsio/oshinko-cli') {
					checkout scm
				}

				// check golang version
				sh('go version')

				// download oc client
				dir('client') {
					sh('curl -LO https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz')
					sh('curl -LO https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz')
					sh('tar -xzf openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz')
					sh('tar -xzf openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz')
					sh('cp openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit/oc .')
					sh('cp openshift-origin-server-v1.5.1-7b451fc-linux-64bit/* .')
				}

				// build
				dir('src/github.com/radanalyticsio/oshinko-cli') {
					sh('make build')
				}
			} catch (err) {
				githubNotify context: 'jenkins-ci/oshinko-cli', description: 'This change cannot be built', status: 'ERROR', targetUrl: buildUrl
				throw err
			}
		}
		stage('Test') {
			try {
				githubNotify(context: 'jenkins-ci/oshinko-cli', description: 'This change is being tested', status: 'PENDING', targetUrl: buildUrl)

				// login to openshift instance
				sh('oc login https://$OCP_HOSTNAME:8443 -u $OCP_USER -p $OCP_PASSWORD --insecure-skip-tls-verify=true')

				// run tests
				dir('src/github.com/radanalyticsio/oshinko-cli') {
					sh('./test/run.sh')
				}
			} catch (err) {
				githubNotify(context: 'jenkins-ci/oshinko-cli', description: 'There are test failures', status: 'FAILURE', targetUrl: buildUrl)
				throw err
			}

			githubNotify(context: 'jenkins-ci/oshinko-cli', description: 'This change looks good', status: 'SUCCESS', targetUrl: buildUrl)
		}
	}
}
