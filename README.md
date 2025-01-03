# jenkins-server
Provision a jenkins-server on aws platform using terraform and terminate the ssl on aws ALB.
NOTE 1: To launch a Jenkins server, comment out the "main.tf" before you run this code.
This code can be used to provision many other server (sonarqube, etc, ...). Just make changes on listen port and other components accordingly in main.tf.
NOTE 2: To launch another server (sonarqube, etc, ...), comment out the "jenkins.tf" and tweak the main.tf accordingly.

