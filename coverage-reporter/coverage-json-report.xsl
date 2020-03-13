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
                expand-text="yes"
                exclude-result-prefixes="#all">

<xsl:import href="./format-utils.xsl" />

<xsl:include href="./xspec-utils.xsl" />

<xsl:output  method="text" indent="yes" media-type="text/json" omit-xml-declaration="yes"/>

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
  <xsl:variable name="result"><xsl:apply-templates select="." mode="test:coverage-report" /></xsl:variable><xsl:value-of select="xml-to-json($result,map{'indent':true()})"/>
</xsl:template>

<xsl:template match="/" mode="test:coverage-report">
  <j:map>
    <xsl:for-each select="trace/m">
      <xsl:variable name="module" select="@id"/>
      <xsl:variable name="file-path" select="fn:substring-after(@u, 'file:')"/>
      
      <j:map key="{$file-path}">
        <j:string key="path">{$file-path}</j:string>

        <j:map key="fnMap"/>
        <j:map key="branchMap"/>
        <j:map key="b"/>
        <j:map key="f"/>
        <j:map key="l"/>

        <j:map key="statementMap">
          <xsl:for-each select="../h[@m=$module]">
            <xsl:variable name="id" select="generate-id(.)"/>
            <xsl:variable name="l" select="@l"/>

            <xsl:variable name="matches" select="key('coverage', concat($module, ':', $l), $trace)"/>
            <xsl:if test="generate-id($matches[1]) = $id">
              <j:map key="{$l}">
                <j:map key="start">
                  <j:number key="line">{@l}</j:number>
                  <j:number key="column">0</j:number>
                </j:map>
                <j:map key="end">
                  <j:number key="line">{@l}</j:number>
                  <j:number key="column">999</j:number>
                </j:map>
              </j:map>
            </xsl:if>
          </xsl:for-each>
        </j:map>

        <j:map key="s">
          <xsl:for-each select="../h[@m=$module]">
            <xsl:variable name="id" select="generate-id(.)"/>
            <xsl:variable name="l" select="@l"/>
            <xsl:variable name="matches" select="key('coverage', concat($module, ':', $l), $trace)"/>
            <xsl:if test="generate-id($matches[1]) = $id">
              <j:number key="{$l}">{count($matches)}</j:number>
            </xsl:if>
          </xsl:for-each>
        </j:map>

      </j:map>
    </xsl:for-each>

  </j:map>
</xsl:template>

</xsl:stylesheet>