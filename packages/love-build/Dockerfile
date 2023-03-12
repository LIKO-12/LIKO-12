FROM alpine:3.10

RUN sudo apk add p7zip wget

RUN wget -O "/templates/appimagetool.AppImage" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-"$(uname -m)".AppImage" && \
  chmod a+x /templates/appimagetool.AppImage
RUN wget -O "/templates/apktool.jar" "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.3.4.jar" && \
  chmod a+x /templates/appimagetool.AppImage

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
