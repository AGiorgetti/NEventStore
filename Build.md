Private Fork Branch usage:

- master: will always be in sync with the origin master branch
- develop: will always be in sync with the origin remote branch

Apply a Simplified flow like this:

- grd_master: will be kept in sync from the remote master (stable) and we apply our very customizations here
- grd_master: is the only branch for which we derive release tags (artifact files will embed the commit hashtag from which they will be generated)

Create a Release Build (NOt using gitversion or semver right now):

- merge all the mods you want to deploy to the grd/master branch
- assign a new tag to the element (major.minor.build) -> should this match the original NEventStore versioning ?
- the actual commit number will anyway be embedded in the AssemblyInformationalVersion

to build:

Build.RunTask GrdPackage (buildNumber - optional)

ex:
Build.RunTask GrdPackage 0

