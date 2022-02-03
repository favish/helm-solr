# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2022-2-3
### Changed
- Renamed the solr service to `solr` from the `fullname` which varied across projects and environments.

## [1.0.1] - 2021-12-14
### Added
- Default resources.

### Security
- Guard against [2021-12-10, Apache Solr affected by Apache Log4J CVE-2021-44228](https://solr.apache.org/security.html#apache-solr-affected-by-apache-log4j-cve-2021-44228)  
  Even though Solr specified that official Docker images are not compromised, a [Docker security blog entry](https://www.docker.com/blog/apache-log4j-2-cve-2021-44228/)
  suggested setting an environment variable for log4j.
  
## [1.0.0] - 2021-11-19
### Added
- Initial release.
