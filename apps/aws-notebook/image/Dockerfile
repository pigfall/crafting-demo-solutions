FROM ubuntu:22.04
RUN apt-get update && apt-get install -y openssh-server python3-pip \
  && pip install ipykernel \
  && mkdir -p ~/.ssh \
  && mkdir -p /run/sshd
CMD ["bash","-c","set -exu; echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys; /usr/sbin/sshd -D -f /etc/ssh/sshd_config"]
