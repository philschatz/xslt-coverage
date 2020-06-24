#!/bin/bash

root_dir="$(dirname "$0")"

COVERAGE_CLASS=com.jenitennison.xslt.tests.XSLTCoverageTraceListener
COVERAGE_IGNORE="${COVERAGE_IGNORE:-./some-unknown-dir/}"

die() {
  echo
  echo "*** $@" >&2
  exit 1
}


# Check that SAXON_HOME and XSPEC_HOME are set
[[ -f ${SAXON_HOME}/saxon9he.jar ]] || die "Set SAXON_HOME to be a directory which contains saxon9he.jar"
[[ -f ${XSPEC_HOME}/java/com/jenitennison/xslt/tests/XSLTCoverageTraceListener.class ]] || die "Clone https://github.com/xspec/xspec and set XSPEC_HOME to be that directory"


xslt_coverage() {
  local xsl_file=$1
  local input_file=$2
  local coverage_file=$3
  local output_file=$4

  local temp_coverage_xml='temp-coverage.xml'
  local coverage_json_reporter="${root_dir}/coverage-reporter/coverage-json2-report.xsl"
  # local coverage_html_reporter="${root_dir}/coverage-reporter/coverage-report.xsl"

  local optional_output=''

  [[ -f ${xsl_file} ]] || die 'Arguments need to be: input_xsl input_xml output_coverage_json optional_output_xml'
  [[ -f ${input_file} ]] || die 'Second argument needs to be the input XML file'
  [[ ${coverage_file} != '' ]] || die 'Third argument needs to be the output coverage JSON file'

  [[ ${output_file} != '' ]] && optional_output="-o:${output_file}"

  case $xsl_file in .*)
      die "Unfortunately, beginning the XSLT file path with a period is not supported. The code coverage lookup seems to silently fail in that case. Just remove the period"
  esac

  java \
    -Dxspec.coverage.ignore="${COVERAGE_IGNORE}" \
    -Dxspec.coverage.xml="${temp_coverage_xml}" \
    -Dxspec.xspecfile="${xsl_file}" \
    -cp "${SAXON_HOME}"/saxon9he.jar:"${XSPEC_HOME}"/java/ \
    net.sf.saxon.Transform \
    "-T:$COVERAGE_CLASS" \
    "-xsl:${xsl_file}" \
    "-s:${input_file}" \
    ${optional_output} || die 'Failed to transform'
  
  java \
      -cp "${SAXON_HOME}"/saxon9he.jar:"${XSPEC_HOME}"/java/ \
      net.sf.saxon.Transform \
      -config:${XSPEC_HOME}/src/reporter/coverage-report-config.xml \
      "-xsl:${coverage_json_reporter}" \
      "-s:${temp_coverage_xml}" \
      "-o:${coverage_file}" || die 'Failed to generate coverage file'
  
  rm "${temp_coverage_xml}" || die 'Failed to remove temporary coverage file'
}

xslt_coverage $@