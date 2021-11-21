FROM atomgraph/saxon

### add stylesheets

COPY xsl/pom2rdfxml.xsl pom2rdfxml.xsl
COPY xsl/deps-traversal.xsl deps-traversal.xsl

RUN ls -l

### entrypoint

ENTRYPOINT ["java", "-jar", "Saxon-HE.jar", "-xsl:deps-traversal.xsl"]