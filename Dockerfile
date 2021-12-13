FROM ubuntu:bionic
# install development tools
RUN apt-get update && \
    apt-get install -y libsecret-1-dev && \
    apt-get install -y curl sudo build-essential jq vim && \
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# add theia installation file
COPY package.json run_theia.sh /theia-app/
RUN chmod +x /theia-app/run_theia.sh

# build theia
WORKDIR /theia-app

RUN yarn && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
	yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean

# Install Python 3 from source
ARG VERSION=3.8.3
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y make build-essential libssl-dev \
    && apt-get install -y libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    && apt-get install -y libncurses5-dev  libncursesw5-dev xz-utils tk-dev \
    && wget https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz \
    && tar xvf Python-$VERSION.tgz \
    && cd Python-$VERSION \
    && ./configure \
    && make -j8 \
    && make install \
    && cd .. \
    && rm -rf Python-$VERSION \
    && rm Python-$VERSION.tgz

RUN apt-get update \
    && apt-get install -y libsecret-1-0 \
    && apt-get install -y python-dev python-pip \
    && pip install --upgrade pip --user \
    && apt-get install -y python3-dev python3-pip \
    && pip3 install --upgrade pip --user \
    && pip3 install python-language-server flake8 autopep8 \
    && apt-get install -y yarn \
    && apt-get clean \
    && apt-get auto-remove -y \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# create debian package
RUN npm run build-deb

# transfer debian package to a new clean image and install theia
FROM ubuntu:bionic
COPY --from=0 /theia-app/theia-example_0.0.1_all.deb /
RUN mkdir -p /home/project
RUN apt-get update && apt-get install -y curl sudo && \
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
	apt-get install -y libsecret-1-0 && \
    apt-get install -y ./theia-example_0.0.1_all.deb && \
	apt-get install -y dos2unix && \
	dos2unix /usr/share/theia-example/app/run_theia.sh
	
ENV SHELL /bin/bash
EXPOSE 3000
CMD ["theia","start","/home/project","--hostname=0.0.0.0"]
