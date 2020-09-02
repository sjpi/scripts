#1)update repo's
sudo apt-get update
#2)install dependencies
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

#3)add GPG key from docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#4)add stable release to repo file
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
#5)update repo's
sudo apt-get update
#6)install docker ce, docker ce cli and containerd
sudo apt-get install docker-ce docker-ce-cli containerd.io
#7)start and automate docker
sudo systemctl start docker && sudo systemctl enable docker
#8)add current user to docker group
sudo usermod -aG docker $USER
#9)close
exit