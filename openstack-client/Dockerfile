FROM ubuntu:14.04
MAINTAINER hafe

# An image with all the OpenStack client packages installed

RUN apt-get update && apt-get install -y \
    libffi-dev \
    libssl-dev \
    python-dev \
    python-pip

RUN pip install python-ceilometerclient
RUN pip install python-cinderclient
RUN pip install python-glanceclient
RUN pip install python-heatclient
RUN pip install python-keystoneclient
RUN pip install python-neutronclient
RUN pip install python-novaclient
RUN pip install python-swiftclient
RUN pip install python-openstackclient

RUN apt-get install -y curl

#RUN pip install \
#    python-troveclient \
#    python-manilaclient

ADD bashrc /root/.bashrc

WORKDIR /root

