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
    <xsl:param name="snapshot-base-uri" select="'https://oss.sonatype.org/content/repositories/snapshots/'" as="xs:string"/>
    <xsl:param name="max-depth" select="2" as="xs:integer"/>

    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="pom:project">
        <xsl:param name="pom-url" select="document-uri()" as="xs:anyURI?" tunnel="yes"/>
        <xsl:param name="artifact-uri" select="xs:anyURI('mvn:' || pom:groupId || ':' || pom:artifactId)" as="xs:anyURI" tunnel="yes"/>

        <Project>
            <xsl:if test="$artifact-uri">
                <xsl:attribute name="rdf:about"><xsl:value-of select="$artifact-uri"/></xsl:attribute>
            </xsl:if>

            <xsl:apply-templates/>
        </Project>
    </xsl:template>

    <!-- special case for SNAPSHOT versions that use a different repository -->
    <xsl:template match="pom:dependency[pom:groupId][pom:artifactId][ends-with(pom:version, '-SNAPSHOT')]" priority="1">
        <xsl:param name="group-id" select="if (pom:groupId = '${project.groupId}' and /pom:project/pom:groupId) then replace(pom:groupId, '\$\{project\.groupId\}', /pom:project/pom:groupId) else pom:groupId" as="xs:string?"/>
        <xsl:param name="artifact-id" select="if (pom:artifactId = '${project.artifactId}' and /pom:project/pom:artifactId) then replace(pom:artifactId, '\$\{project\.artifactId\}', /pom:project/pom:artifactId) else pom:artifactId" as="xs:string?"/>
        <xsl:param name="version" select="if (pom:version = '${project.version}' and /pom:project/pom:version) then replace(pom:version, '\$\{project\.version\}', /pom:project/pom:version) else pom:version" as="xs:string?"/>
        <xsl:param name="mvn-id" select="$group-id || ':' || $artifact-id || ':' || $version" as="xs:string"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="level" select="0" as="xs:integer" tunnel="yes"/>
        <xsl:param name="maven-metadata-relative-url" select="translate($group-id, '.', '/') || '/' || $artifact-id || '/' || $version || '/' || 'maven-metadata.xml'" as="xs:string"/>

        <xsl:try>
            <xsl:variable name="maven-metadata-url" select="resolve-uri($maven-metadata-relative-url, $snapshot-base-uri)" as="xs:anyURI"/>

            <xsl:message>SNAPSHOT maven-metadata: <xsl:value-of select="$maven-metadata-url"/></xsl:message>

            <xsl:if test="doc-available($maven-metadata-url)">
                <xsl:variable name="version-no-snapshot" select="substring-before($version, '-SNAPSHOT')" as="xs:string"/>
                <xsl:variable name="maven-metadata" select="document($maven-metadata-url)" as="document-node()"/>
                <xsl:variable name="timestamp" select="$maven-metadata/metadata/versioning/snapshot/timestamp" as="xs:string"/>
                <xsl:variable name="build-number" select="$maven-metadata/metadata/versioning/snapshot/buildNumber" as="xs:string"/>
                <xsl:variable name="pom-relative-url" select="translate($group-id, '.', '/') || '/' || $artifact-id || '/' || $version || '/' || $artifact-id || '-' || $version-no-snapshot || '-' || $timestamp || '-' || $build-number || '.pom'" as="xs:string"/>

                <xsl:next-match>
                    <xsl:with-param name="group-id" select="$group-id"/>
                    <xsl:with-param name="artifact-id" select="$artifact-id"/>
                    <xsl:with-param name="version" select="$version"/>
                    <xsl:with-param name="pom-relative-url" select="$pom-relative-url"/>
                    <xsl:with-param name="mvn-base-uri" select="$snapshot-base-uri"/>
                </xsl:next-match>
            </xsl:if>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="$maven-metadata-relative-url"/>' to URL</xsl:message>

                <xsl:apply-imports/>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <!-- we need version to build the .pom URL -->
    <xsl:template match="pom:dependency[pom:groupId][pom:artifactId][pom:version]">
        <xsl:param name="group-id" select="if (pom:groupId = '${project.groupId}' and /pom:project/pom:groupId) then replace(pom:groupId, '\$\{project\.groupId\}', /pom:project/pom:groupId) else pom:groupId" as="xs:string?"/>
        <xsl:param name="artifact-id" select="if (pom:artifactId = '${project.artifactId}' and /pom:project/pom:artifactId) then replace(pom:artifactId, '\$\{project\.artifactId\}', /pom:project/pom:artifactId) else pom:artifactId" as="xs:string?"/>
        <xsl:param name="version" select="if (pom:version = '${project.version}' and /pom:project/pom:version) then replace(pom:version, '\$\{project\.version\}', /pom:project/pom:version) else pom:version" as="xs:string?"/>
        <xsl:param name="mvn-id" select="$group-id || ':' || $artifact-id || ':' || $version" as="xs:string"/>
        <xsl:param name="traversed-ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="level" select="0" as="xs:integer" tunnel="yes"/>
        <xsl:param name="pom-relative-url" select="translate($group-id, '.', '/') || '/' || $artifact-id || '/' || $version || '/' || $artifact-id || '-' || $version || '.pom'" as="xs:string"/>
        <xsl:param name="mvn-base-uri" select="$mvn-base-uri" as="xs:string"/>

        <xsl:message>
Dependency level: <xsl:value-of select="$level"/>
Artifact: <xsl:value-of select="$mvn-id"/>
        </xsl:message>

        <xsl:try>
            <xsl:variable name="pom-url" select="resolve-uri($pom-relative-url, $mvn-base-uri)" as="xs:anyURI"/>
            <xsl:variable name="artifact-uri" select="xs:anyURI('mvn:' || $group-id || ':' || $artifact-id)" as="xs:anyURI"/>
            <xsl:variable name="version-uri" select="xs:anyURI('mvn:' || $group-id || ':' || $artifact-id || ':' || $version)" as="xs:anyURI"/>

<xsl:message>POM: <xsl:value-of select="$pom-url"/>
Artifact URI: <xsl:value-of select="$artifact-uri"/>
Version URI: <xsl:value-of select="$version-uri"/>
</xsl:message>

            <xsl:choose>
                <xsl:when test="$level &lt; $max-depth and not($mvn-id = $traversed-ids) and doc-available($pom-url)">
                    <deps:build-requirement>
                        <deps:Dependency>
                            <deps:on>
                                <Version rdf:about="{$version-uri}">
                                    <revision>
                                        <xsl:value-of select="pom:version"/>
                                    </revision>
                                    
                                    <!-- There is no doap:releaseOf property :/ But using the inverse doap:release would be much more complicated -->
                                    <releaseOf>
                                        <xsl:apply-templates select="document($pom-url)/pom:project">
                                            <xsl:with-param name="artifact-uri" select="$artifact-uri" tunnel="yes"/>
                                            <xsl:with-param name="level" select="$level + 1" tunnel="yes"/>
                                            <xsl:with-param name="traversed-ids" select="($mvn-id, $traversed-ids)" tunnel="yes"/>
                                        </xsl:apply-templates>
                                    </releaseOf>
                                </Version>
                            </deps:on>
                        </deps:Dependency>
                    </deps:build-requirement>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-imports/>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:catch errors="err:FORG0002">
                <xsl:message>Could not cast '<xsl:value-of select="$pom-relative-url"/>' to URL</xsl:message>

                <xsl:apply-imports/>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

</xsl:stylesheet>