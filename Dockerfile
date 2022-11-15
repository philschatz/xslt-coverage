FROM klakegg/saxon:he

ENV XSPEC_VER 1.6.0

RUN wget -O /xspec.zip https://github.com/xspec/xspec/archive/refs/tags/v${XSPEC_VER}.zip && unzip -d / /xspec.zip

ENV XSPEC_HOME /xspec-${XSPEC_VER}
# ENV SAXON_HOME /usr/share/java/saxon


COPY xslt-coverage.bash .
COPY all.cnxml cnxml-to-html5.xsl ./
COPY coverage-reporter/ ./coverage-reporter

RUN echo "Running test" && sh ./xslt-coverage.bash cnxml-to-html5.xsl all.cnxml coverage.json out.xhtml && cat coverage.json; echo "" && echo "" && echo "Ran test. Coverage JSON should be above" && echo ""

ENTRYPOINT [ "sh" ]