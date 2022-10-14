FROM ubuntu:22.04
RUN apt-get update && apt-get install openssh-server  -y && mkdir -p ~/.ssh &&  mkdir -p /run/sshd

CMD ["bash","-c","set -exu; echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys; /usr/sbin/sshd -D -f /etc/ssh/sshd_config"]
