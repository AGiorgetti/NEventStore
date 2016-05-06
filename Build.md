Private Fork Branch usage:

- master: will always be in sync with the origin master branch
- develop: will always be in sync with the origin remote branch

Apply a Simplified flow like this:

- grd_master: will be kept in sync from the remote master (stable) and we apply our very customizations here
- grd_master: is the only branch for which we derive release tags (artifact files will embed the commit hashtag from which they will be generated)

to build:

Build.RunTask GrdPackage (buildNumber - optional)

ex:
Build.RunTask GrdPackage 0