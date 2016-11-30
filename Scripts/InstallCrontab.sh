`crontab -l  | grep -i DockerRemoveOldContainers || cat <(crontab -l) <(echo "0 * * * * /cyrusworks/source/Scripts/DockerRemoveOldContainers.sh") | crontab -`;
