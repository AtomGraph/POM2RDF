# POM2RDF

Transforms Maven POM file into an RDF graph of project dependencies.

It is implemented as an [XSLT 3.0](https://www.w3.org/TR/xslt-30/) stylesheet that starts from the initial POM project, traverses down the dependency tree and embeds the metadata of the depending projects recursively.

Uses the [DOAP](http://usefulinc.com/ns/doap) and [doap-deps](http://ontologi.es/doap-deps) vocabularies. The output is in the [RDF/XML](https://www.w3.org/TR/rdf-syntax-grammar/) format.

## Usage

Mount the POM file as volume and run the container to get the output in `doap.rdf`:

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml > doap.rdf

Note that we use `$PWD` in order to make host filepath absolute, as required by Docker's [`-v` (volume) option](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems).

### Parameters

#### `max-depth`

The max depth of the dependency tree to be traversed (by default 2):

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml max-depth=1000 > doap.rdf

#### `mvn-base-uri`

The base URL that relative URLs constructed from `<groupId>`/`<artifactId>`/`<version>` are resolved against (by default `https://repo1.maven.org/maven2/`):

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml mvn-base-uri=https://oss.sonatype.org/content/repositories/releases/ > doap.rdf

## Notes

`<version>${project.version}</version>` is the only POM expression that will be recognized and replaced with a value. There is currently no support for Maven features such as parent POMs etc.

Any other expressions will lead to invalid Maven POM URLs and therefore will not be dereferenced and the dependency metadata will not be embedded.

Cyclical dependencies are broken by not embedding any occurrence other than the first.

## Sample

[Sample RDF output](sample/doap.rdf) generated from [LinkedDataHub's POM](https://github.com/AtomGraph/LinkedDataHub/blob/master/pom.xml) using `max-depth=1`.