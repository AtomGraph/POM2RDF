# POM2RDF

Transforms Maven POM file into an RDF graph of project dependencies. It can be used to generate a dependency graph or a software bill of materials.

It is implemented as an [XSLT 3.0](https://www.w3.org/TR/xslt-30/) stylesheet that starts from the initial POM project, traverses down the dependency tree and embeds the metadata of the depending projects recursively.

## Usage

Mount the POM file as volume and run the container to get the output in `doap.rdf`:

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml > doap.rdf

Note that we use `$PWD` in order to make host filepath absolute, as required by Docker's [`-v` (volume) option](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems).

### Parameters

#### `max-depth`

The max depth of the dependency tree to be traversed (by default 2):

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml max-depth=1000 > doap.rdf

#### `mvn-base-uri`

The base URL that relative POM URLs (constructed from `<groupId>`/`<artifactId>`/`<version>`) are resolved against (by default `https://repo1.maven.org/maven2/`):

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml mvn-base-uri=https://oss.sonatype.org/content/repositories/releases/ > doap.rdf

#### `snapshot-base-uri`

The base URL that POM relative URLs of `SNAPSHOT` versions (constructed from `<groupId>`/`<artifactId>`/`<version>`) are resolved against (by default `https://oss.sonatype.org/content/repositories/snapshots/`):

    docker run --rm -v "$PWD/pom.xml":"/xml/pom.xml" atomgraph/pom2rdf -s:/xml/pom.xml snapshot-base-uri=https://s01.oss.sonatype.org/content/repositories/snapshots/ > doap.rdf

## Notes

The only POM expressions that will be recognized and replaced with a value are:
* `<groupId>${project.groupId}</groupId>`
* `<pom:artifactId>${project.artifactId}</pom:artifactId>`
* `<version>${project.version}</version>`

There is currently no support for Maven features such as parent POMs etc.

Any other expressions will lead to invalid Maven POM URLs and therefore will not be dereferenced and the dependency metadata will not be embedded.

`SNAPSHOT` versions are supported, their POMs use looked up in a different Maven repository (see [`snapshot-base-uri`](#snapshot-base-uri)).

Cyclical dependencies are broken by not embedding any occurrence other than the first.

## Output

The output is in the [RDF/XML](https://www.w3.org/TR/rdf-syntax-grammar/) format. It uses the [DOAP](http://usefulinc.com/ns/doap) and [doap-deps](http://ontologi.es/doap-deps) vocabularies.

A non-existing `mvn:` URI scheme is used to identify and reconcile artifacts and their versions, for example `mvn:com.atomgraph:linkeddatahub`.

Property `doap:releaseOf` is not defined by DOAP but is used as the inverse of `doap:release`.

[Sample RDF output](sample/doap.rdf) generated from [LinkedDataHub's POM](https://github.com/AtomGraph/LinkedDataHub/blob/master/pom.xml) using `max-depth=1`.