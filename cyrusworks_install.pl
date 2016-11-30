#!/usr/bin/perl
# http://cyrus.works install script
# Author : Chris Davies [ chris@cyrus.works ]
# This script assumes:
# -Git is installed
# -This install script has been cloned to /cyrusworks/

#Kill and remove existing cyrusworks containers and files:
`sudo docker stop cyrusworks-jenkins && docker rm -f cyrusworks-jenkins`;
`rm -rf /cyrusworks/jenkins/`;

#Make it obvious what server this is:
`sudo cp /cyrusworks/source/StaticFiles/motd /etc/motd`;

#Bring the server up to date:
`apt-get update -y && apt-get upgrade -y`;

#Install everything we need:
`sudo apt-get install -y nginx ufw fail2ban sudo curl unattended-upgrades wget ntp make squid3`;
`service squid3 stop`;

#Configure ufw
`sudo ufw allow 22`; #Allow SSH access
`sudo ufw allow 80`; #Allow http access

#Create & setup new user 'cyrusworks'
`sudo useradd -s /bin/bash -m -d /cyrusworks cyrusworks`;
`sudo echo "cyrusworks ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers`;
`su - cyrusworks -c "mkdir -p /cyrusworks/source /cyrusworks/jenkins/plugins /cyrusworks/cwPluginBackup /cyrusworks/www"`;
`sudo chown -R cyrusworks /cyrusworks/`;
#`git clone https://github.com/FMQA/cyrusworks.git /cyrusworks/source/`; #Source code will already be on FastMail servers
`git -C /cyrusworks/source/ pull`;
`git -C /cyrusworks/cyrus-docker/ pull`;

#Stop NGINX for now so the world can't see a half configured Jenkins:
`sudo service nginx stop`;

#Install & configure docker
`docker version || wget -qO- https://get.docker.com/|sh`;
`sudo usermod -aG docker cyrusworks`;

#Start the docker container:
chomp($user_id = `id -u cyrusworks`);
print "\nDocker images : `docker ps -a `";
system("sudo docker run -p 127.0.0.1:8080:8080 -u $user_id -d --name=cyrusworks-jenkins -v /cyrusworks/cyrus-docker/:/cyrusworks/cyrus-docker/ -v /cyrusworks/jenkins/:/var/jenkins_home/ -v /cyrusworks/source/Scripts/:/cyrusworks/scripts/ -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v /cyrusworks/jenkins/:/var/jenkins_home/ jenkins");

#Get the initial randomly generated password:
print "\nWaiting for the password to be generated...";
sleep 15; #It takes a few seconds for Jenkins to generate the initial admin password:
my $admin_password=`cat /cyrusworks/jenkins/secrets/initialAdminPassword`;
unless (-e "/cyrusworks/jenkins/secrets/initialAdminPassword") {die("\n Jenkins initial admin password not written to file. Check docker logs. The install has failed");}

#Start services:
`sudo ufw --force enable`;
`sudo service fail2ban start`;

#Remove the "getting started" guide screen
`sudo echo "2.0" > /cyrusworks/jenkins/jenkins.install.InstallUtil.lastExecVersion`;

#Install previously downloaded plugins, if they're stored locally:
`sudo cp /cyrusworks/cwPluginBackup/*.hpi /cyrusworks/jenkins/plugins/`;

#Fetch plugins that aren't stored locally
foreach my $i (0..1) {
	foreach my $package ('bouncycastle-api.hpi', 'cloudbees-folder.hpi', 'structs.hpi', 'junit.hpi', 'antisamy-markup-formatter.hpi', 'pam-auth.hpi', 'windows-slaves.hpi', 'display-url-api.hpi', 'mailer.hpi', 'ldap.hpi', 'token-macro.hpi', 'external-monitor-job.hpi', 'icon-shim.hpi', 'matrix-auth.hpi', 'script-security.hpi', 'matrix-project.hpi', 'build-timeout.hpi', 'credentials.hpi', 'workflow-step-api.hpi', 'plain-credentials.hpi', 'credentials-binding.hpi', 'timestamper.hpi', 'ws-cleanup.hpi', 'ant.hpi', 'gradle.hpi', 'workflow-api.hpi', 'pipeline-milestone-step.hpi', 'workflow-support.hpi', 'pipeline-build-step.hpi', 'jquery-detached.hpi', 'ace-editor.hpi', 'workflow-scm-step.hpi', 'scm-api.hpi', 'workflow-cps.hpi', 'pipeline-input-step.hpi', 'pipeline-stage-step.hpi', 'workflow-job.hpi', 'pipeline-graph-analysis.hpi', 'pipeline-rest-api.hpi', 'handlebars.hpi', 'momentjs.hpi', 'pipeline-stage-view.hpi', 'ssh-credentials.hpi', 'git-client.hpi', 'git-server.hpi', 'workflow-cps-global-lib.hpi', 'branch-api.hpi', 'workflow-multibranch.hpi', 'durable-task.hpi', 'workflow-durable-task-step.hpi', 'workflow-basic-steps.hpi', 'workflow-aggregator.hpi', 'github-api.hpi', 'git.hpi', 'github.hpi', 'github-branch-source.hpi', 'github-organization-folder.hpi', 'mapdb-api.hpi', 'subversion.hpi', 'ssh-slaves.hpi', 'email-ext.hpi', 'javadoc.hpi', 'maven-plugin.hpi', 'dashboard-view.hpi', 'throttle-concurrents.hpi', 'run-condition.hpi', 'conditional-buildstep.hpi', 'parameterized-trigger.hpi', 'emailext-template.hpi', 'greenballs.hpi', 'simple-theme-plugin.hpi','docker-build-step.hpi','docker-commons.hpi','authentication-tokens.hpi','docker-plugin.hpi','resource-disposer.hpi') {

		print "\nInstalling Jenkins plugin : $package";

		#Download it package if it doesn't exist on the host machine:
		unless (-e "/cyrusworks/jenkins/plugins/$package") {
		print "\n ...It doesn't exist locally. Downloading...";
		`wget https://updates.jenkins-ci.org/latest/$package -P /cyrusworks/jenkins/plugins`;
		}
	}
sleep 1;
print "\nRetrying plugins that failed to download...";
}

#Store the plugins locally to speed up reinstalling cyrus.works
`sudo cp /cyrusworks/jenkins/plugins/*.hpi /cyrusworks/cwPluginBackup/`;

#Copy the Jenkins config.xml in to place:
`cp /cyrusworks/source/config/jenkins_config.xml /cyrusworks/jenkins/config.xml`;
`cp /cyrusworks/source/StaticFiles/502.html /cyrusworks/www/index.html`;

#Copy the theme in to place:
`sudo cp /cyrusworks/source/config/org.codefirst.SimpleThemeDecorator.xml /cyrusworks/jenkins/`;
`sudo chown -R cyrusworks /cyrusworks/jenkins`;

#Change owner of all cyrusworks files:
`sudo chown -R cyrusworks /cyrusworks`;

#Restart Jenkins:
`sudo docker restart cyrusworks-jenkins`;

#Pull cyrus-docker from github:
`mkdir /cyrusworks/cyrus-docker`;
`git clone https://github.com/cyrusimap/cyrus-docker.git /cyrusworks/cyrus-docker/`;

#Remove operating systems that won't be part of cyrus.works
`cd /cyrusworks/cyrus-docker; rm -rf bottle harlequin heisenbug precise rawhide santiago squeeze tikanga.obsolete tumbleweed twentyone utopic vivid`;

#Configure Jenkins:
system("docker exec -u root cyrusworks-jenkins bash -c /cyrusworks/scripts/SetupJenkins.sh");

my @DockerImages = split /\n/, `cd /cyrusworks/cyrus-docker/; egrep -l -i 'FROM ' * | egrep -v "*.sh|*.pl" | sort | uniq`;

foreach my $DockerImage (@DockerImages)
{
	print "\nSetup : $DockerImage";
	#Create a Jenkins job
	`mkdir -p /cyrusworks/jenkins/jobs/master-$DockerImage/`;

	#Create a Jenkins job for each DockerFile
	`cp /cyrusworks/source/config/jenkins_job_config.xml /cyrusworks/jenkins/jobs/master-$DockerImage/config.xml`;
	system("sed -i -e \"s#cyrusworks_place_DockerImage_here#$DockerImage#g\" /cyrusworks/jenkins/jobs/master-$DockerImage/config.xml");

}

#Generate master job that can trigger all other builds. Github will call this:
`mkdir -p /cyrusworks/jenkins/jobs/ci/`;
`cp /cyrusworks/source/config/jenkins_ci_job_config.xml /cyrusworks/jenkins/jobs/ci/config.xml`;

#Set the CI token:
open(FILE, '/cyrusworks/github_token ') or die "Can't read file github ci token\n";  
my $ci_token = <FILE>; 
close (FILE);  
system("sed -i -e \"s#cyrus_works_place_github_token_here#$ci_token#g\" /cyrusworks/jenkins/jobs/ci/config.xml");

#Set file ownership & restart Jenkins:
`sudo chown -R cyrusworks /cyrusworks/; `;
`docker restart cyrusworks-jenkins`;

#Configure & NGINX proxy"
`sudo cp /cyrusworks/source/config/nginx_config /etc/nginx/sites-enabled/default`;

#Start NGINX:
`sudo nginx -t && sudo service nginx start`;

#If a Docker cleanup crontab doesn't already exist, install one. This will remove old docker containers once per hour: 
#`crontab -l  | grep -i DockerRemoveOldContainers || cat <(crontab -l) <(echo "0 * * * * /cyrusworks/source/Scripts/DockerRemoveOldContainers.sh") | crontab -`;
print "\n\nThe admin password is : $admin_password \n";
