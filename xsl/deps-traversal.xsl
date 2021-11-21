<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright (C) 2021 Martynas Jusevičius <martynas@atomgraph.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY doap   "http://usefulinc.com/ns/doap#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY deps   "https://ontologi.es/doap-deps#">
]>
<xsl:stylesheet version="3.0"
xmlns="&doap;"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:err="http://www.w3.org/2005/xqt-errors"
xmlns:rdf="&rdf;"
xmlns:foaf="&foaf;"
xmlns:deps="&deps;"
xmlns:pom="http://maven.apache.org/POM/4.0.0"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
exclude-result-prefixes="#all">

    <xsl:import href="pom2rdfxml.xsl"/>

    <xsl:output method="xml" indent="yes" encoding="UTF-8" media-type="application/rdf+xml"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:mode on-no-match="deep-skip"/>

    <xsl:param name="mvn-base-uri" select="'https://repo1.maven.org/maven2/'" as="xs:string"/>
    <xsl:param name="max-depth" select="2" as="xs:integer"/>

    <!-- we need version to build the .pom URL -->
    <xsl:template match="pom:dependency[pom:version]">
        <xsl:param name="mvn-id" select="pom:groupId || ':' || pom:artifactId || ':' || pom:version" as="xs:string"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="level" select="0" as="xs:integer" tunnel="yes"/>
        <xsl:variable name="pom-relative-url" select="translate(pom:groupId, '.', '/') || '/' || pom:artifactId || '/' || pom:version || '/' || pom:artifactId || '-' || pom:version || '.pom'" as="xs:string"/>
        <xsl:variable name="pom-relative-url" select="if (contains($pom-relative-url, '${project.version}') and /pom:project/pom:version) then replace($pom-relative-url, '\$\{project\.version\}', /pom:project/pom:version) else $pom-relative-url" as="xs:string"/>

        <xsl:message>
Dependency level: <xsl:value-of select="$level"/>
Artifact: <xsl:value-of select="$mvn-id"/>
        </xsl:message>

        <xsl:try>
            <xsl:variable name="pom-url" select="resolve-uri($pom-relative-url, $mvn-base-uri)" as="xs:anyURI"/>
            <xsl:variable name="project-relative-uri" select="translate(pom:groupId, '.', '/') || '/' || pom:artifactId || '#project'" as="xs:string"/>
            <xsl:variable name="project-uri" select="resolve-uri($project-relative-uri, $mvn-base-uri)" as="xs:anyURI"/>

<xsl:message>POM: <xsl:value-of select="$pom-url"/>
Project URI: <xsl:value-of select="$project-uri"/>
</xsl:message>

            <xsl:choose>
                <xsl:when test="$level &lt; $max-depth and not($mvn-id = $traversed-ids) and doc-available($pom-url)">
                    <deps:build-requirement>
                        <deps:Dependency>
                            <deps:on>
                                <xsl:apply-templates select="document($pom-url)/pom:project">
                                    <xsl:with-param name="project-uri" select="$project-uri" tunnel="yes"/>
                                    <xsl:with-param name="level" select="$level + 1" tunnel="yes"/>
                                    <xsl:with-param name="traversed-ids" select="($mvn-id, $traversed-ids)" tunnel="yes"/>
                                </xsl:apply-templates>
                            </deps:on>
                        </deps:Dependency>
                    </deps:build-requirement>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:next-match/>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>


</xsl:stylesheet>