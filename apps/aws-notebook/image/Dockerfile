FROM ubuntu:22.04
RUN apt-get update && apt-get install openssh-server -y && mkdir -p ~/.ssh &&  mkdir -p /run/sshd
RUN useradd -m owner \
  && usermod --shell /bin/bash owner \
  && mkdir /home/owner/.ssh \
  && chown owner /home/owner/.ssh \
  && touch /home/owner/.ssh/authorized_keys \
  && chown owner /home/owner/.ssh/authorized_keys
RUN apt-get install pip -y
RUN pip install notebook


CMD ["bash","-c","set -exu; echo ${PUBLIC_KEY} >> /home/owner/.ssh/authorized_keys; echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys; /usr/sbin/sshd -D -f /etc/ssh/sshd_config"]
