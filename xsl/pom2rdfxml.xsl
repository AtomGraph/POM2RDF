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

    <xsl:output method="xml" indent="yes" encoding="UTF-8" media-type="application/rdf+xml"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:mode on-no-match="deep-skip"/>

    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="pom:project[pom:groupId][pom:artifactId]">
        <xsl:param name="artifact-uri" select="xs:anyURI('mvn:' || pom:groupId || ':' || pom:artifactId)" as="xs:anyURI" tunnel="yes"/>

        <Project>
            <xsl:if test="$artifact-uri">
                <xsl:attribute name="rdf:about"><xsl:value-of select="$artifact-uri"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates/>
        </Project>
    </xsl:template>

    <xsl:template match="pom:name">
        <name>
            <xsl:value-of select="."/>
        </name>
    </xsl:template>

    <xsl:template match="pom:description">
        <description>
            <xsl:value-of select="."/>
        </description>
    </xsl:template>

    <xsl:template match="pom:licenses">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pom:license">
        <license>
            <foaf:Document>
                <xsl:apply-templates/>
            </foaf:Document>
        </license>
    </xsl:template>

    <xsl:template match="pom:project/pom:version">
        <release>
            <Version>
                <revision>
                    <xsl:value-of select="."/>
                </revision>
            </Version>
        </release>
    </xsl:template>

    <!-- Saxon allows URIs such as 'git@github.com:cbeust/testng.git' but they seem to be invalid, so Jena fails parsing them -->
    <xsl:template match="pom:url">
        <xsl:try>
            <homepage rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:developers">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pom:developer">
        <maintainer>
            <foaf:Person>
                <xsl:apply-templates/>
            </foaf:Person>
        </maintainer>
    </xsl:template>

<!--     <xsl:template match="pom:organization">
        <vendor>
            <foaf:Organization>
                <foaf:name>
                    <xsl:value-of select="."/>
                </foaf:name>
            </foaf:Organization>
        </vendor>
    </xsl:template> -->

    <xsl:template match="pom:email">
        <xsl:try>
            <foaf:mbox rdf:resource="{resolve-uri('mailto:' || .)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:organizationUrl">
        <xsl:try>
            <foaf:workplaceHomepage rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:scm[starts-with(pom:connection, 'scm:git')]">
        <repository>
            <GitRepository>
                <xsl:apply-templates/>
            </GitRepository>
        </repository>
    </xsl:template>

    <xsl:template match="pom:scm/pom:url" priority="1">
        <xsl:try>
            <browse rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:connection">
        <xsl:try>
            <location rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:dependencies">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pom:dependency[pom:artifactId]">
        <xsl:param name="group-id" select="if (pom:groupId = '${project.groupId}' and /pom:project/pom:groupId) then replace(pom:groupId, '\$\{project\.groupId\}', /pom:project/pom:groupId) else pom:groupId" as="xs:string?"/>
        <xsl:param name="artifact-id" select="if (pom:artifactId = '${project.artifactId}' and /pom:project/pom:artifactId) then replace(pom:artifactId, '\$\{project\.artifactId\}', /pom:project/pom:artifactId) else pom:artifactId" as="xs:string?"/>
        <xsl:param name="mvn-id" select="$group-id || ':' || $artifact-id" as="xs:string"/>

        <deps:build-requirement>
            <deps:Dependency>
                <deps:on rdf:resource="{'mvn:' || $mvn-id}"/>
            </deps:Dependency>
        </deps:build-requirement>
    </xsl:template>

    <xsl:template match="pom:dependency[pom:artifactId][pom:version]" priority="1">
        <xsl:param name="group-id" select="if (pom:groupId = '${project.groupId}' and /pom:project/pom:groupId) then replace(pom:groupId, '\$\{project\.groupId\}', /pom:project/pom:groupId) else pom:groupId" as="xs:string?"/>
        <xsl:param name="artifact-id" select="if (pom:artifactId = '${project.artifactId}' and /pom:project/pom:artifactId) then replace(pom:artifactId, '\$\{project\.artifactId\}', /pom:project/pom:artifactId) else pom:artifactId" as="xs:string?"/>
        <xsl:param name="version" select="if (pom:version = '${project.version}' and /pom:project/pom:version) then replace(pom:version, '\$\{project\.version\}', /pom:project/pom:version) else pom:version" as="xs:string?"/>
        <xsl:param name="mvn-id" select="$group-id || ':' || $artifact-id || ':' || $version" as="xs:string"/>

        <deps:build-requirement>
            <deps:Dependency>
                <deps:on rdf:resource="{'mvn:' || $mvn-id}"/>
            </deps:Dependency>
        </deps:build-requirement>
    </xsl:template>

</xsl:stylesheet>