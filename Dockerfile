FROM swift:5.8.1-focal as swift-format-builder
ADD . /toolbox
WORKDIR /toolbox
RUN swift build -c release -Xswiftc -static-executable
