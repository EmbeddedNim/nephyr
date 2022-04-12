ARG FROM_TAG
ARG CI_GIT_NI_TOKEN

FROM zephyrprojectrtos/ci:${FROM_TAG:-latest}

RUN apt-get -y update \
    && apt-get -y upgrade \
	&& apt-get install --no-install-recommends -y \
		python-xdg software-properties-common \
		vim libpython3.8-dev \
		makeself p7zip-full tree curl \
		ca-certificates bash-completion \
		python3-dev python3-pip python3-tk python3-wheel \
		libusb-1.0-0-dev libusb-dev \
		socat \
		ssh \
		tio \
		wget \
		xz-utils \
		udev \
		debhelper \
		cmake \
		iputils-ping \
		netcat \
		kmod \
	&& rm -rf /var/lib/apt/lists/*

RUN wget --post-data "accept_license_agreement=accepted" \
			-O /opt/JLink_Linux_x86_64.deb \
			https://www.segger.com/downloads/jlink/JLink_Linux_V758c_x86_64.deb  \
	&& dpkg -i /opt/JLink_Linux_x86_64.deb \
	&& rm /opt/JLink_Linux_x86_64.deb

RUN wget https://github.com/stlink-org/stlink/releases/download/v1.7.0/stlink_1.7.0-1_amd64.deb \
			-O /opt/stlink_amd64.deb \
	&& mkdir -p /lib/modules/`uname -r` \
	&& dpkg -i /opt/stlink_amd64.deb \
	&& rm /opt/stlink_amd64.deb 

# Install python packages to allow upload to aws S3
RUN mkdir -p /home/user/.bash_completion.d
RUN chown -R user:user /home/user
RUN echo 'export PATH=$HOME/.nimble/bin:$HOME/Nim/bin:$PATH' >> /etc/profile.d/nimble.sh

USER user

RUN pip3 install setuptools awscli \
	&& python3 -mpip install -U pyocd

ENV ZEPHYR_HOME=/home/user/zephyrproject
RUN cd /home/user/ \
	&& west init -m https://github.com/EmbeddedNim/zephyr --mr nephyr-v2.7-branch-patched ${ZEPHYR_HOME} \
	&& cd ${ZEPHYR_HOME} \
	&& west update \
	&& cd $HOME

RUN cd ${ZEPHYR_HOME}/tools/net-tools/ \
	&& make

# RUN cd $HOME/ \
# 	&& wget https://nim-lang.org/choosenim/init.sh \
# 	&& sh init.sh -y \
# 	&& ~/.nimble/bin/choosenim -y 'devel' --latest \
# 	&& cd ~/.choosenim/toolchains/nim-#devel \
# 	&& git remote add fork https://github.com/EmbeddedNim/Nim.git \
# 	&& git fetch fork \
# 	&& git reset --hard \
# 	&& git checkout -t fork/devel-patched \
# 	&& ./build_all.sh

RUN cd $HOME/ \
	&& git clone --branch devel-patched --depth=1 https://github.com/EmbeddedNim/Nim.git \
	&& cd Nim \
	&& ./build_all.sh \
	&& echo 'export PATH=$HOME/Nim/bin:$PATH' >> ~/.bashrc

RUN mkdir ${HOME}/app/ \
	&& touch ${HOME}/.bashrc \
  && echo 'alias gs="git status"' >> ${HOME}/.bashrc \
  && echo 'alias gc="git commit"' >> ${HOME}/.bashrc \
  && echo 'alias gp="git push"' >> ${HOME}/.bashrc \
  && echo 'alias gu="git pull"' >> ${HOME}/.bashrc \
  && echo 'alias gf="git diff"' >> ${HOME}/.bashrc 

RUN . /etc/profile.d/nimble.sh \
	&& echo "2022-04-12-r1" \
	&& cd ${HOME} \
	&& git clone --branch main 'https://github.com/EmbeddedNim/nephyr.git' && cd nephyr/ && nimble develop -y \
	&& cd ${HOME} \
	&& git clone --branch main 'https://github.com/EmbeddedNim/mcu_utils.git' && cd mcu_utils/ && nimble develop -y \
	&& cd ${HOME} \
	&& git clone --branch devel 'https://github.com/EmbeddedNim/fastrpc.git' && cd fastrpc/ && nimble develop -y \
	&& cd ${HOME} \
	&& git clone --branch main "https://github.com/EmbeddedNim/devicedrivers.git" && cd devicedrivers/ && nimble develop -y

ADD update-all-deps.sh /home/user/update-all-deps.sh

WORKDIR /home/user/
VOLUME ["/home/user/app/"]

CMD ["/bin/bash", "-l"]
