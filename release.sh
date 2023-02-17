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
   isValidVersionParam "$1"
   isValidVersionParam "$2"
fi

# The actual release & snapshot versions
RELEASE_VERSION=$1
SNAPSHOT_VERSION="$2"-SNAPSHOT

git checkout develop

./mvnw versions:set "-DnewVersion=${SNAPSHOT_VERSION}" && ./mvnw versions:commit
./mvnw versions:set-property -Dproperty=code-conventions.version "-DnewVersion=${SNAPSHOT_VERSION}" && ./mvnw versions:commit
./mvnw clean install
./mvnw versions:set-property -Dproperty=code-conventions.version "-DnewVersion=${RELEASE_VERSION}" && ./mvnw versions:commit
./mvnw versions:set "-DnewVersion=${RELEASE_VERSION}" && ./mvnw versions:commit

git add -u
git commit -m "Update pom.xml for release/$RELEASE_VERSION"
git checkout master
git merge develop

./mvnw install
./mvnw versions:set-property -Dproperty=code-conventions.release.version "-DnewVersion=${RELEASE_VERSION}"
./mvnw versions:commit
./mvnw install

git add -u
git commit -m "release/$RELEASE_VERSION"
git tag "$RELEASE_VERSION"

# Set snapshot version
git checkout develop
git merge master
./mvnw versions:set-property -Dproperty=code-conventions.version "-DnewVersion=${SNAPSHOT_VERSION}" && ./mvnw versions:commit
./mvnw versions:set-property -Dproperty=code-conventions.release.version "-DnewVersion=${SNAPSHOT_VERSION}" && ./mvnw versions:commit
./mvnw versions:set "-DnewVersion=${SNAPSHOT_VERSION}" && ./mvnw versions:commit

git add -u
git commit -m "Update pom.xml for $SNAPSHOT_VERSION development"

git push -u origin develop
git push -u origin master
git push origin "$RELEASE_VERSION"
