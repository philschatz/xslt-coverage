<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:j="http://www.w3.org/2005/xpath-functions"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:coverage="https://openstax.org/xsl-coverage"
                expand-text="yes"
                exclude-result-prefixes="#all">

<!-- 

This file copies from coverage-report.xsl to do 2 things:

1. highlight the entire open tag instead of just the last line of the open tag
2. Highlight the close tags
3. Report missed lines

Most of the code is copied.
Templates containing "j:" and "coverage:" are modified.

-->

<xsl:import href="./format-utils.xsl" />

<xsl:include href="./xspec-utils.xsl" />

<xsl:output  method="text" indent="yes" media-type="text/json" omit-xml-declaration="yes" />
<!-- <xsl:output method="xml" indent="true" /> -->

<xsl:variable name="trace" as="document-node()" select="/" />


<xsl:variable name="stylesheet-uri" as="xs:anyURI"
  select="$trace/trace/@xspec" />

<xsl:variable name="stylesheet-trees" as="document-node()+"
  select="test:collect-stylesheets(doc($stylesheet-uri))" />

<xsl:function name="test:collect-stylesheets" as="document-node()+">
  <xsl:param name="stylesheets" as="document-node()+" />
  <xsl:variable name="imports" as="document-node()*"
    select="document($stylesheets/*/(xsl:import|xsl:include)/@href)" />
  <xsl:variable name="new-stylesheets" as="document-node()*"
    select="$stylesheets | $imports" />
  <xsl:choose>
    <xsl:when test="$imports except $stylesheets">
      <xsl:sequence select="test:collect-stylesheets($stylesheets | $imports)" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="$stylesheets" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:key name="modules" match="m" use="@u" />
<xsl:key name="constructs" match="c" use="@id" />
<xsl:key name="coverage" match="h" use="concat(@m, ':', @l)" />

<xsl:template match="/">
  <xsl:variable name="result">
    <xsl:apply-templates select="." mode="test:coverage-report" />
  </xsl:variable>
  <!-- Do not indent because the coverage-highlighter
      plugin assumes the string `"path":` exists (no space in front of the colon)
      https://github.com/pilat/vscode-coverage-highlighter/blob/master/src/parsers/istanbulParser.ts#L70 
  -->
  <xsl:value-of select="xml-to-json($result,map{'indent':false()})" />
</xsl:template>
<!-- <xsl:template match="/">
  <xsl:apply-templates select="." mode="test:coverage-report" />
</xsl:template> -->


<xsl:template match="/" mode="test:coverage-report">
  <j:map>
    <xsl:apply-templates select="$stylesheet-trees/xsl:*" mode="test:coverage-report" />
  </j:map>
</xsl:template>



<xsl:template match="xsl:stylesheet | xsl:transform" mode="test:coverage-report">
  <xsl:variable name="stylesheet-uri" as="xs:anyURI"
    select="base-uri(.)" />
  <xsl:variable name="stylesheet-tree" as="document-node()"
    select=".." />
  <xsl:variable name="stylesheet-string" as="xs:string"
    select="unparsed-text($stylesheet-uri)" />
  <xsl:variable name="stylesheet-lines" as="xs:string+" 
    select="test:split-lines($stylesheet-string)" />
  <xsl:variable name="number-of-lines" as="xs:integer"
    select="count($stylesheet-lines)" />
  <xsl:variable name="number-width" as="xs:integer"
    select="string-length(xs:string($number-of-lines))" />
  <xsl:variable name="number-format" as="xs:string"
  select="string-join(for $i in 1 to $number-width return '0', '')" />
  <xsl:variable name="module" as="xs:string?">
    <xsl:variable name="uri" as="xs:string"
      select="if (starts-with($stylesheet-uri, '/'))
              then concat('file:', $stylesheet-uri)
              else $stylesheet-uri" />
    <xsl:sequence select="key('modules', $uri, $trace)/@id" />
  </xsl:variable>
  <xsl:variable name="file-path" select="x:format-uri($stylesheet-uri)" />
  <xsl:if test="not(empty($module))">
    <xsl:variable name="lines">
      <xsl:call-template name="test:output-lines">
        <xsl:with-param name="line-number" select="0" />
        <xsl:with-param name="stylesheet-string" select="$stylesheet-string" />
        <xsl:with-param name="node" select="." />
        <xsl:with-param name="number-format" tunnel="yes" select="$number-format" />
        <xsl:with-param name="module" tunnel="yes" select="$module" />
      </xsl:call-template>
    </xsl:variable>

    <j:map key="{$file-path}">
      <j:string key="path">{$file-path}</j:string>
      <j:map key="fnMap" />
      <j:map key="branchMap" />
      <j:map key="b" />
      <j:map key="f" />
      <j:map key="l" />

      <j:map key="statementMap">
        <xsl:for-each select="$lines/coverage:line-info">
          <xsl:variable name="l" select="@line" />
          <xsl:variable name="status" select="@status" />
          <xsl:variable name="id" select="generate-id(.)" />
          <xsl:choose>
            <xsl:when test="$status = 'ignore'" />
            <xsl:otherwise>
              <j:map key="{$id}">
                <j:map key="start">
                  <j:number key="line">{$l}</j:number>
                  <j:number key="column">0</j:number>
                </j:map>
                <j:map key="end">
                  <j:number key="line">{$l}</j:number>
                  <j:number key="column">999</j:number>
                </j:map>
              </j:map>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </j:map>

      <j:map key="s">
        <xsl:for-each select="$lines/coverage:line-info">
          <xsl:variable name="id" select="generate-id(.)" />
          <xsl:variable name="l" select="@line" />
          <xsl:variable name="status" select="@status" />
          <xsl:choose>
            <xsl:when test="$status = 'ignored'" />
            <xsl:when test="$status = 'hit'">
              <j:number key="{$id}">12345</j:number>
            </xsl:when>
            <xsl:when test="$status = 'missed'">
              <j:number key="{$id}">0</j:number>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message terminate="yes">Unknown status="{$status}". Expected ignored,hit,missed</xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </j:map>

    </j:map>
  </xsl:if>

</xsl:template>

<xsl:variable name="attribute-regex" as="xs:string">
  <xsl:value-of>
    \s+
    ([^>\s]+)      <!-- 1: the name of the attribute -->
    \s*
    =
    \s*
    (          <!-- 2: the value of the attribute (with quotes) -->
      "([^"]*)"  <!-- 3: the value without quotes -->
      |
      '([^']*)'  <!-- 4: also the value without quotes -->
    )
  </xsl:value-of>
</xsl:variable>

<xsl:variable name="construct-regex" as="xs:string">
  <xsl:value-of>
    ^
    (             <!-- 1: the construct -->
      ([^&lt;]+)    <!-- 2: some text -->
      |
      (&lt;!--     <!-- 3: a comment -->
        ([^-]|-[^-])*  <!-- 4: the content of the comment -->
       --&gt;)
      |
      (&lt;\?      <!-- 5: a PI -->
        ([^?]|\?[^>])*  <!-- 6: the content of the PI -->
       \?&gt;)
      |
      (&lt;!\[CDATA\[   <!-- 7: a CDATA section -->
        ([^\]]|\][^\]]|\]\][^>])*  <!-- 8: the content of the CDATA section -->
       \]\]>)
      |
      (&lt;/     <!-- 9: a close tag -->
        ([^>]+)   <!-- 10: the name of the element being closed -->
       >)
      |
      (&lt;      <!-- 11: an open tag -->
        ([^>/\s]+)    <!-- 12: the name of the element being opened -->
        (        <!-- 13: the attributes of the element -->
          (      <!-- 14: wrapper for the attribute regex -->
            <xsl:value-of select="$attribute-regex" />  <!-- 15-18 attribute stuff -->
          )*
        )
        \s*
        (/?)      <!-- 19: empty element tag flag -->
        >
      )
    )
    (.*)          <!-- 20: the rest of the string -->
    $
  </xsl:value-of>
</xsl:variable>

<xsl:template name="test:output-lines">
  <xsl:context-item use="absent"
    use-when="element-available('xsl:context-item')" />

  <xsl:param name="line-number" as="xs:integer" required="yes" />
  <xsl:param name="stylesheet-string" as="xs:string" required="yes" />
  <xsl:param name="node" as="node()" required="yes" />
  <xsl:param name="number-format" tunnel="yes" as="xs:string" required="yes" />
  <xsl:param name="module" tunnel="yes" as="xs:string" required="yes" />

  <xsl:variable name="analyzed">
    <xsl:analyze-string select="$stylesheet-string"
      regex="{$construct-regex}" flags="sx">
      <xsl:matching-substring>
        <xsl:variable name="construct" as="xs:string" select="regex-group(1)" />
        <xsl:variable name="rest" as="xs:string" select="regex-group(20)" />
        <xsl:variable name="construct-lines" as="xs:string+"
          select="test:split-lines($construct)" />
        <xsl:variable name="endTag" as="xs:boolean" select="regex-group(9) != ''" />
        <xsl:variable name="emptyTag" as="xs:boolean" select="regex-group(19) != ''" />
        <xsl:variable name="startTag" as="xs:boolean" select="not($emptyTag) and regex-group(11) != ''" />
        <xsl:variable name="matches" as="xs:boolean"
          select="($node instance of text() and
                   (regex-group(2) != '' or regex-group(7) != '')) or
                  ($node instance of element() and
                   ($startTag or $endTag or $emptyTag) and
                   name($node) = (regex-group(10), regex-group(12))) or
                  ($node instance of comment() and
                   regex-group(3) != '') or
                  ($node instance of processing-instruction() and
                  regex-group(5) != '')" />
        <xsl:variable name="coverage" as="xs:string" 
          select="if ($matches) then test:coverage($node, $module) else 'ignored'" />
        <xsl:for-each select="$construct-lines">
          <coverage:line-info line="{$line-number + position()}" status="{$coverage}" />
        </xsl:for-each>
        <!-- Capture the residue, tagging it for later analysis and processing. -->
        <test:residue matches="{$matches}" startTag="{$startTag}" rest="{$rest}" count="{count($construct-lines)}" />
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:message terminate="yes">
          unmatched string: <xsl:value-of select="." />
        </xsl:message>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:variable>
  <xsl:sequence select="$analyzed/node()[not(self::test:residue)]" />
  <xsl:variable name="residue" select="$analyzed/test:residue" />
  <xsl:if test="$residue/@rest != ''">
    <!-- The last thing this template does is call itself.
         Tail recursion prevents stack overflow. -->
    <xsl:call-template name="test:output-lines">
      <xsl:with-param name="line-number" select="$line-number + xs:integer($residue/@count) - 1" />
      <xsl:with-param name="stylesheet-string" select="string($residue/@rest)" />
      <xsl:with-param name="node" as="node()">
        <xsl:choose>
          <xsl:when test="$residue/@matches = 'true'">
            <xsl:choose>
              <xsl:when test="$residue/@startTag = 'true'">
                <xsl:choose>
                  <xsl:when test="$node/node()">
                    <xsl:sequence select="$node/node()[1]" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="$node" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="$node/following-sibling::node()">
                    <xsl:sequence select="$node/following-sibling::node()[1]" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="$node/parent::node()" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$node" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param> 
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<xsl:function name="test:coverage" as="xs:string">
  <xsl:param name="node" as="node()" />
  <xsl:param name="module" as="xs:string" />
  <xsl:variable name="coverage" as="xs:string+">
    <xsl:apply-templates select="$node" mode="test:coverage">
      <xsl:with-param name="module" tunnel="yes" select="$module" />
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:if test="count($coverage) > 1">
    <xsl:message terminate="yes">
      more than one coverage identified for:
      <xsl:sequence select="$node" />
    </xsl:message>
  </xsl:if>
  <xsl:sequence select="$coverage[1]" />
</xsl:function>

<xsl:template match="text()[normalize-space(.) = '' and not(parent::xsl:text)]" mode="test:coverage">ignored</xsl:template>

<xsl:template match="processing-instruction() | comment()" mode="test:coverage">ignored</xsl:template>

<!-- A hit on these nodes doesn't really count; you have to hit
     their contents to hit them -->
<xsl:template match="xsl:otherwise | xsl:when | xsl:matching-substring | xsl:non-matching-substring | xsl:for-each | xsl:for-each-group" mode="test:coverage">
  <xsl:param name="module" tunnel="yes" as="xs:string" required="yes" />
  <xsl:variable name="hits-on-content" as="element(h)*"
    select="test:hit-on-nodes(node(), $module)" />
  <xsl:choose>
    <xsl:when test="exists($hits-on-content)">hit</xsl:when>
    <xsl:otherwise>missed</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="* | text()" mode="test:coverage">
  <xsl:param name="module" tunnel="yes" as="xs:string" required="yes" />
  <xsl:variable name="hit" as="element(h)*"
    select="test:hit-on-nodes(., $module)" />
  <xsl:choose>
    <xsl:when test="exists($hit)">hit</xsl:when>
    <xsl:when test="self::text() and normalize-space(.) = '' and not(parent::xsl:text)">ignored</xsl:when>
    <xsl:when test="self::xsl:variable">
      <xsl:sequence select="test:coverage(following-sibling::*[not(self::xsl:variable)][1], $module)" />
    </xsl:when>
    <xsl:when test="ancestor::xsl:variable">
      <xsl:sequence select="test:coverage(ancestor::xsl:variable[1], $module)" />
    </xsl:when>
    <xsl:when test="self::xsl:stylesheet or self::xsl:transform">ignored</xsl:when>
    <xsl:when test="self::xsl:function or self::xsl:template">missed</xsl:when>
    <!-- A node within a top-level non-XSLT element -->
    <xsl:when test="empty(ancestor::xsl:*[parent::xsl:stylesheet or parent::xsl:transform])">ignored</xsl:when>
    <xsl:when test="self::xsl:param">
      <xsl:sequence select="test:coverage(parent::*, $module)" />
    </xsl:when>
    <xsl:otherwise>missed</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="/" mode="test:coverage">ignored</xsl:template>

<xsl:function name="test:hit-on-nodes" as="element(h)*">
  <xsl:param name="nodes" as="node()*" />
  <xsl:param name="module" as="xs:string" />
  <xsl:for-each select="$nodes[not(self::text()[not(normalize-space())])]">
    <xsl:variable name="hits" as="element(h)*"
      select="test:hit-on-lines(x:line-number(.), $module)" />
    <xsl:variable name="name" as="xs:string"
      select="concat('{', namespace-uri(.), '}', local-name(.))" />
    <xsl:for-each select="$hits">
      <xsl:variable name="construct" as="xs:string"
        select="key('constructs', @c)/@n" />
      <xsl:if test="$name = $construct or
                    not(starts-with($construct, '{'))">
        <xsl:sequence select="." />
      </xsl:if>
    </xsl:for-each>
  </xsl:for-each>
</xsl:function>

<xsl:function name="test:hit-on-lines" as="element(h)*">
  <xsl:param name="line-numbers" as="xs:integer*" />
  <xsl:param name="module" as="xs:string" />
  <xsl:variable name="keys" as="xs:string*"
    select="for $l in $line-numbers
            return concat($module, ':', $l)" />
  <xsl:sequence select="key('coverage', $keys, $trace)" />
</xsl:function>



<xsl:function name="test:split-lines" as="xs:string+">
  <xsl:param name="input" as="xs:string" />

  <!-- Regular expression is based on http://www.w3.org/TR/xpath-functions-31/#func-unparsed-text-lines -->
  <xsl:sequence select="tokenize($input, '\r\n|\r|\n')" />
</xsl:function>

</xsl:stylesheet>