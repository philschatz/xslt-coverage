#!/bin/bash

COVERAGE_CLASS=com.jenitennison.xslt.tests.XSLTCoverageTraceListener
COVERAGE_IGNORE="./some-unknown-dir/"
coverage_html_reporter=./coverage-reporter/coverage-report.xsl
coverage_json_reporter=./coverage-reporter/coverage-json2-report.xsl

die() {
    echo
    echo "*** $@" >&2
    exit 1
}


xslt() {
  # Replace -T:${COVERAGE_CLASS} with the following to get performance numbers:
  # (both cannot run at the same time)
  # "-TP:${xsl_file}.profile.xhtml" \

  coverage_xml=$1
  xsl_file=$2
  java \
      -Dxspec.coverage.ignore="${COVERAGE_IGNORE}" \
      -Dxspec.coverage.xml="${coverage_xml}" \
      -Dxspec.xspecfile="${xsl_file}" \
      -cp "${SAXON_HOME}"/saxon9he.jar:"${XSPEC_HOME}"/java/ \
      net.sf.saxon.Transform \
      "-T:$COVERAGE_CLASS" \
      "-xsl:${xsl_file}" ${@:3}
}

coverage_html() {
    coverage_xml=$1
    xslt_file=$2
    html_report=$3

    java \
      -cp "${SAXON_HOME}"/saxon9he.jar:"${XSPEC_HOME}"/java/ \
      net.sf.saxon.Transform \
      -config:${XSPEC_HOME}/src/reporter/coverage-report-config.xml \
      -s:${coverage_xml} \
      -o:${html_report} \
      -xsl:${coverage_html_reporter} \
      inline-css=true
}

coverage_json() {
    coverage_filename=$1
    xslt_file=$2
    html_report=$3

    java \
      -cp "${SAXON_HOME}"/saxon9he.jar:"${XSPEC_HOME}"/java/ \
      net.sf.saxon.Transform \
      -config:${XSPEC_HOME}/src/reporter/coverage-report-config.xml \
      -s:${coverage_filename} \
      -o:${html_report} \
      -xsl:${coverage_json_reporter} \
      inline-css=true
}

xslt_coverage() {
  temp_coverage="./coverage-temp.xml"
  xslt_file=$1
  coverage_report="${xslt_file}.coverage.xhtml"

  [[ -f "${temp_coverage}" ]] && rm "${temp_coverage}"

  echo "Transforming using ${xslt_file}"
  xslt ${temp_coverage} $@
  echo "Generating JSON coverage report for ${xslt_file}"
  coverage_json ${temp_coverage} ${xslt_file} "./coverage/coverage-final.json"
  echo "Generating HTML coverage report for ${xslt_file}"
  coverage_html ${temp_coverage} ${xslt_file} ${coverage_report}
}


# Check that SAXON_HOME and XSPEC_HOME are set
[[ -f ${SAXON_HOME}/saxon9he.jar ]] || die "Set SAXON_HOME to be a directory which contains saxon9he.jar"
[[ -f ${XSPEC_HOME}/java/com/jenitennison/xslt/tests/XSLTCoverageTraceListener.class ]] || die "Clone https://github.com/xspec/xspec and set XSPEC_HOME to be that directory"

[[ -d "./coverage/" ]] || mkdir "./coverage/"

xslt_coverage2() {

  source_file=$1
  xslt_file="cnxml-to-html5.xsl"
  coverage_report="${xslt_file}.coverage.xhtml"
  base="$(basename ${source_file})"
  final_home="coverage-${base}.xhtml"
  xslt_coverage "${xslt_file}" "-s:${source_file}" -o:/dev/null
  mv "./coverage-temp.xml" "./coverage-${base}.xml"
  mv "${coverage_report}" "${final_home}"

}

xslt_coverage2 "./all.cnxml"
# xslt_coverage2 "./test/cite.cnxml"
# xslt_coverage2 "./test/cite.html.cnxml"
# xslt_coverage2 "./test/classed.cnxml"
# xslt_coverage2 "./test/classed.html.cnxml"
# xslt_coverage2 "./test/code.cnxml"
# xslt_coverage2 "./test/code.html.cnxml"
# xslt_coverage2 "./test/data-dash.html.cnxml"
# xslt_coverage2 "./test/definition.cnxml"
# xslt_coverage2 "./test/definition.html.cnxml"
# xslt_coverage2 "./test/div.html.cnxml"
# xslt_coverage2 "./test/div_span_not_self_closing.cnxml"
# xslt_coverage2 "./test/emphasis.cnxml"
# xslt_coverage2 "./test/emphasis.html.cnxml"
# xslt_coverage2 "./test/figure.cnxml"
# xslt_coverage2 "./test/figure.html.cnxml"
# xslt_coverage2 "./test/footnote.cnxml"
# xslt_coverage2 "./test/footnote.html.cnxml"
# xslt_coverage2 "./test/glossary.cnxml"
# xslt_coverage2 "./test/glossary.html.cnxml"
# xslt_coverage2 "./test/img-longdesc.cnxml"
# xslt_coverage2 "./test/label.cnxml"
# xslt_coverage2 "./test/label.html.cnxml"
# xslt_coverage2 "./test/link.cnxml"
# xslt_coverage2 "./test/link.html.cnxml"
# xslt_coverage2 "./test/list.cnxml"
# xslt_coverage2 "./test/list.html.cnxml"
# xslt_coverage2 "./test/math_problem_m65735.cnxml"
# xslt_coverage2 "./test/media.cnxml"
# xslt_coverage2 "./test/media.html.cnxml"
# xslt_coverage2 "./test/newline.cnxml"
# xslt_coverage2 "./test/newline.html.cnxml"
# xslt_coverage2 "./test/note.cnxml"
# xslt_coverage2 "./test/note.html.cnxml"
# xslt_coverage2 "./test/para.cnxml"
# xslt_coverage2 "./test/problem_m58457_1.6.self_closing.cnxml"
# xslt_coverage2 "./test/table.cnxml"
# xslt_coverage2 "./test/table.html.cnxml"
# xslt_coverage2 "./test/term-and-link.cnxml"
# xslt_coverage2 "./test/term-and-link.html.cnxml"
# xslt_coverage2 "./test/title.cnxml"
# xslt_coverage2 "./test/title.html.cnxml"
# xslt_coverage2 "./test/xhtml-characters.cnxml"