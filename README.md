# xslt-coverage

## Prerequisites

1. Install [saxon-he 9.9](https://sourceforge.net/projects/saxon/files/Saxon-HE/9.9/) (or `brew install saxon`)
1. Download [xspec/xspec](https://github.com/xspec/xspec)
1. Set `SAXON_HOME` and `XSPEC_HOME` to point to their respective directories

## Usage

```sh
./xslt-coverage.bash ${input_xsl} ${input_xml} ${output_coverage_json} ${optional_output_xml}

# Generate Istanbul-compatible coverage files
node mergeCoverageFiles.js cov1.json cov2.json cov3.json ... > coverage/coverage-final.json
```

## Verification

1. Run `bash ./test-coverage.bash` to generate a `coverage/coverage-final.json`
1. Install [vscode-coverage-highlighter](https://github.com/pilat/vscode-coverage-highlighter)
1. Open [./cnxml-to-html5.xsl](./cnxml-to-html5.xsl) in the editor and see the code coverage


![xslt coverage](https://user-images.githubusercontent.com/253202/76597517-a73c2a00-64ce-11ea-9a86-9898cac674ec.png)
