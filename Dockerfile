# syntax=docker/dockerfile:1
FROM yegor256/rultor-image

# Install Appium
RUN apt update && apt -y upgrade && \
    apt install -y m4 libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev \
    curl dirmngr apt-transport-https lsb-release ca-certificates gcc g++ make npm && \
    sudo npm install n -g && \
    sudo n stable && \
    sudo npm install -g appium --unsafe-perm=true --allow-root

# Initialize directories
RUN mkdir /code && \
    mkdir /code/engine

# Download Android command-line tools
WORKDIR /code
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7302050_latest.zip && \
    unzip ./commandlinetools-linux-7302050_latest.zip -d sdk  && \
    rm ./commandlinetools-linux-7302050_latest.zip
WORKDIR /code/sdk
RUN mv cmdline-tools tools && \
    mkdir cmdline-tools && \
    mkdir cmdline-tools/tools && \
    mv tools/* cmdline-tools/tools && \
    rm -rf tools

# Set PATH values
ENV ANDROID_HOME /code/sdk
ENV PATH "${PATH}:${ANDROID_HOME}:${ANDROID_HOME}/tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/tools/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/bin"

# Accept Google licenses and install SDKs
#WORKDIR /code/sdk/tools/bin
RUN yes | sdkmanager --licenses
RUN sdkmanager "system-images;android-29;default;x86"
RUN sdkmanager "build-tools;30.0.3"
RUN sdkmanager "platform-tools"
RUN sdkmanager "platforms;android-29"

# Install bundler and gems from Gemfile
WORKDIR /code/engine
COPY Gemfile /code/engine/Gemfile
RUN gem install bundler && bundle install

# Run script that creates unique emulator
WORKDIR /code/engine
VOLUME /code/avds
ENV production = 1
ENV ANDROID_AVD_HOME /code/android_avds
COPY skins /code/sdk/skins
RUN touch ~/.android/repositories.cfg && \
    mkdir /code/android_avds

ENTRYPOINT ["/bin/bash", "--login", "-c"]
COPY . /code/engine
RUN ruby create_emu.rb