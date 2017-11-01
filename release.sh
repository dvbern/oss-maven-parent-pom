#!/usr/bin/env bash
set -e

function isValidVersionParam() {
    if ! [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version parameter $1"
        exit 1
    fi
}

if [ ! $# -eq 2 ]; then
    echo "Specify release and next release versions."
    echo "Example: $0 0.33.0 0.34.0"
    exit 1;
else
   isValidVersionParam $1
   isValidVersionParam $2
fi

# The actual release & snapshot versions
RELEASE_VERSION=$1
SNAPSHOT_VERSION="$2"-SNAPSHOT

# maven-enforcer-plugin check fails when updateDependencies is activated.
# Thus we have to update the versions in such a complicated fashion.
mvn -U jgitflow:release-start -DreleaseVersion=${RELEASE_VERSION} -DdevelopmentVersion=${SNAPSHOT_VERSION} -DupdateDependencies=false -DallowUntracked=true

mvn versions:set-property -Dproperty=code-conventions.version -DnewVersion=${RELEASE_VERSION}
mvn versions:set -DnewVersion=${RELEASE_VERSION}
mvn versions:commit

git add -u
git commit -m "Update pom.xml for release/$RELEASE_VERSION"

# Update release version in develop branch to avoid merge conflicts
git checkout develop
git pull
mvn versions:set -DnewVersion=${RELEASE_VERSION}
mvn versions:commit

git add -u
git commit -m "updating develop versions to master versions to avoid merge conflicts"

## Der Befehl hat irgendwie zu einem Fehler maven-enforcer error geführt aber es hat trotzdem funktioniert!?
mvn -U jgitflow:release-finish -DnoReleaseBuild=false -DupdateDependencies=false -DautoVersionSubmodules=false

# Set snapshot version
git checkout develop
mvn versions:set-property -Dproperty=code-conventions.version -DnewVersion=${SNAPSHOT_VERSION}
mvn versions:set -DnewVersion=${SNAPSHOT_VERSION}
mvn versions:commit

git add -u
git commit -m "Update pom.xml for $SNAPSHOT_VERSION development"
git push
