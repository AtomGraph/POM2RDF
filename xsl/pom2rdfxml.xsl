<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright (C) 2019 Martynas Jusevičius <martynas@graphity.org>

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
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY owl    "http://www.w3.org/2002/07/owl#">
    <!ENTITY doap   "http://usefulinc.com/ns/doap#">
    <!ENTITY foaf   "http://xmlns.com/foaf/0.1/">
    <!ENTITY deps   "https://ontologi.es/doap-deps#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/2000/svg"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:err="http://www.w3.org/2005/xqt-errors"
xmlns:ac="&ac;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:xsd="&xsd;"
xmlns:owl="&owl;"
xmlns:doap="&doap;"
xmlns:foaf="&foaf;"
xmlns:deps="&deps;"
xmlns:pom="http://maven.apache.org/POM/4.0.0"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:math="http://www.w3.org/2005/xpath-functions/math"
exclude-result-prefixes="#all">

    <xsl:output method="xml" indent="yes" encoding="UTF-8" media-type="application/rdf+xml"/>
    
    <xsl:strip-space elements="*"/>
    
    <xsl:mode on-no-match="deep-skip"/>

    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="pom:project">
        <doap:Project>
            <xsl:apply-templates/>
        </doap:Project>
    </xsl:template>

    <xsl:template match="pom:name">
        <doap:name>
            <xsl:value-of select="."/>
        </doap:name>
    </xsl:template>

    <xsl:template match="pom:description">
        <doap:description>
            <xsl:value-of select="."/>
        </doap:description>
    </xsl:template>

    <xsl:template match="pom:licenses">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pom:license">
        <doap:license>
            <foaf:Document>
                <xsl:apply-templates/>
            </foaf:Document>
        </doap:license>
    </xsl:template>

    <xsl:template match="pom:project/pom:version">
        <doap:release>
            <doap:Version>
                <doap:revision>
                    <xsl:value-of select="."/>
                </doap:revision>
            </doap:Version>
        </doap:release>
    </xsl:template>

    <!-- Saxon allows URIs such as 'git@github.com:cbeust/testng.git' but they seem to be invalid, so Jena fails parsing them -->
    <xsl:template match="pom:url">
        <xsl:try>
            <doap:homepage rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:developers">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pom:developer">
        <doap:maintainer>
            <foaf:Person>
                <xsl:apply-templates/>
            </foaf:Person>
        </doap:maintainer>
    </xsl:template>

<!--     <xsl:template match="pom:organization">
        <doap:vendor>
            <foaf:Organization>
                <foaf:name>
                    <xsl:value-of select="."/>
                </foaf:name>
            </foaf:Organization>
        </doap:vendor>
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
        <doap:repository>
            <doap:GitRepository>
                <xsl:apply-templates/>
            </doap:GitRepository>
        </doap:repository>
    </xsl:template>

    <xsl:template match="pom:scm/pom:url" priority="1">
        <xsl:try>
            <doap:browse rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:connection">
        <xsl:try>
            <doap:location rdf:resource="{resolve-uri(.)}"/>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="."/>' to URL</xsl:message>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="pom:dependencies">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pom:dependency">
        <deps:build-requirement>
            <deps:Dependency>
                <deps:on rdf:datatype="&deps;MvnId">
                    <xsl:value-of select="pom:groupId"/>
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="pom:artifactId"/>
                    <xsl:if test="pom:version">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="pom:version"/>
                    </xsl:if>
                </deps:on>
            </deps:Dependency>
        </deps:build-requirement>
    </xsl:template>

</xsl:stylesheet>