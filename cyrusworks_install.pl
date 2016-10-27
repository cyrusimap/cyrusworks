#!/usr/bin/perl
# http://cyrus.works install script
# Author : Chris Davies [ chris@cyrus.works ]
# This script assumes
# -Git is installed
# -This install script has been cloned to /cyrusworks/
# -This script isn't being run as soon.

#Kill and remove existing cyrusworks containers and files:
`sudo docker stop cyrusworks-jenkins && docker rm -f cyrusworks-jenkins`;

#Make it obvious what server this is:
`sudo cp /cyrusworks/source/StaticFiles/motd /etc/motd`;

#Bring the server up to date:
`apt-get update -y && apt-get upgrade -y`;

#Install everything we need:
`sudo apt-get install -y nginx ufw fail2ban sudo curl unattended-upgrades wget ntp`;

#Configure ufw
`sudo ufw allow 22`; #Allow SSH access
`sudo ufw allow 80`; #Allow http access

#Create & setup new user 'cyrusworks'
`sudo useradd -s /bin/bash -m -d /cyrusworks cyrusworks`;
`sudo echo "cyrusworks ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers`;
`su - cyrusworks -c "mkdir -p /cyrusworks/source /cyrusworks/jenkins/plugins"`;
`sudo chown -R cyrusworks /cyrusworks/`;
`git clone https://github.com/FMQA/cyrusworks.git /cyrusworks/source/`;

#Configure & NGINX proxy"
`sudo cp /cyrusworks/source/config/nginx_config /etc/nginx/sites-enabled/default`;

#Stop NGINX for now so the world can't see a half configured Jenkins:
`sudo service nginx stop`;

#Install & configure docker
`wget -qO- https://get.docker.com/|sh`;
`sudo usermod -aG docker cyrusworks`;

my $user_id = `id -u cyrusworks`;
chomp($user_id);

#Start the docker container:
`sudo docker run -p 127.0.0.1:8080:8080 -u $user_id -d --name=cyrusworks-jenkins -v /cyrusworks/jenkins/:/var/jenkins_home/ jenkins`;

#Display the initial randomly generated password:
print "\nWaiting for the password to be generated...";
sleep 15; #It takes a few seconds for Jenkins to generate the initial admin password:
print "\nFetching password...";
my $admin_password=`cat /cyrusworks/jenkins/secrets/initialAdminPassword`;

#Start services:
`sudo ufw --force enable`;
`sudo service fail2ban start`;

#Remove the "getting started" guide screen
`sudo echo "2.0" > /cyrusworks/jenkins/jenkins.install.InstallUtil.lastExecVersion`;


#Install plugins:
`sudo cp /cwplugins/* /cyrusworks/jenkins/plugins/`;

foreach my $package ('bouncycastle-api.hpi', 'cloudbees-folder.hpi', 'structs.hpi', 'junit.hpi', 'antisamy-markup-formatter.hpi', 'pam-auth.hpi', 'windows-slaves.hpi', 'display-url-api.hpi', 'mailer.hpi', 'ldap.hpi', 'token-macro.hpi', 'external-monitor-job.hpi', 'icon-shim.hpi', 'matrix-auth.hpi', 'script-security.hpi', 'matrix-project.hpi', 'build-timeout.hpi', 'credentials.hpi', 'workflow-step-api.hpi', 'plain-credentials.hpi', 'credentials-binding.hpi', 'timestamper.hpi', 'ws-cleanup.hpi', 'ant.hpi', 'gradle.hpi', 'workflow-api.hpi', 'pipeline-milestone-step.hpi', 'workflow-support.hpi', 'pipeline-build-step.hpi', 'jquery-detached.hpi', 'ace-editor.hpi', 'workflow-scm-step.hpi', 'scm-api.hpi', 'workflow-cps.hpi', 'pipeline-input-step.hpi', 'pipeline-stage-step.hpi', 'workflow-job.hpi', 'pipeline-graph-analysis.hpi', 'pipeline-rest-api.hpi', 'handlebars.hpi', 'momentjs.hpi', 'pipeline-stage-view.hpi', 'ssh-credentials.hpi', 'git-client.hpi', 'git-server.hpi', 'workflow-cps-global-lib.hpi', 'branch-api.hpi', 'workflow-multibranch.hpi', 'durable-task.hpi', 'workflow-durable-task-step.hpi', 'workflow-basic-steps.hpi', 'workflow-aggregator.hpi', 'github-api.hpi', 'git.hpi', 'github.hpi', 'github-branch-source.hpi', 'github-organization-folder.hpi', 'mapdb-api.hpi', 'subversion.hpi', 'ssh-slaves.hpi', 'email-ext.hpi', 'javadoc.hpi', 'maven-plugin.hpi', 'dashboard-view.hpi', 'throttle-concurrents.hpi', 'run-condition.hpi', 'conditional-buildstep.hpi', 'parameterized-trigger.hpi', 'emailext-template.hpi', 'greenballs.hpi', 'simple-theme-plugin.hpi', 'AnsiColor.hpi','docker-build-step.hpi','docker-commons.hpi','authentication-tokens.hpi','docker-plugin.hpi') {

	print "\nInstalling Jenkins plugin : $package";

	#Download it package if it doesn't exist on the host machine:
	unless (-e "/cyrusworks/jenkins/plugins/$package") {
	print "\n ...It doesn't exist locally. Downloading...";
	`wget https://updates.jenkins-ci.org/latest/$package -P /cyrusworks/jenkins/plugins`
	}
}

#Copy the Jenkins config.xml in to place:
`cp /cyrusworks/source/config/jenkins-config.xml /cyrusworks/jenkins/config.xml`;

#Copy the theme in to place:
`sudo cp /cyrusworks/source/config/org.codefirst.SimpleThemeDecorator.xml /cyrusworks/jenkins/`;
`sudo chown -R cyrusworks /cyrusworks/jenkins`;

#Change the permissions of the plugins:
`sudo chown -R cyrusworks /cyrusworks`;

#Restart Jenkins:
`sudo docker restart cyrusworks-jenkins`;

#Start NGINX:
`sudo nginx -t && sudo service nginx start`;

print "\n\nThe admin password is : $admin_password \n";
