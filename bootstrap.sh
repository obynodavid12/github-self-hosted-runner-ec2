#!/bin/bash
yum update -y

# install docker
amazon-linux-extras install -y docker
service docker start
chkconfig docker on
usermod -a -G docker ec2-user

# install git
yum install git make -y

# install github runner application
sudo -u ec2-user mkdir /home/ec2-user/actions-runner
sudo -u ec2-user curl -o /home/ec2-user/actions-runner/actions-runner-linux-x64-2.290.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.290.1/actions-runner-linux-x64-2.290.1.tar.gz
sudo -u ec2-user tar xzf /home/ec2-user/actions-runner/actions-runner-linux-x64-2.290.1.tar.gz -C /home/ec2-user/actions-runner
sudo -u ec2-user EC2_INSTANCE_ID=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id` bash -c 'cd /home/ec2-user/actions-runner/;./config.sh --url ${github_repo_url} --pat ${personal_access_token} --name "${runner_name}-$${EC2_INSTANCE_ID}" --work _work --labels ${labels} --runasservice'

# start the github runner as a service on startup
cd /home/ec2-user/actions-runner/;./svc.sh install
cd /home/ec2-user/actions-runner/;./svc.sh start
