#!/bin/bash
#
# Utility, originally from  Matthias Sohn (bug 450186), to check who has
# committed to "simrel.build" repo, but then has not, for one year.
# Part of a routine yearly process to remove inactive committers from
# callisto-dev.

# This script can be ran in an "complete clone" of org.eclipse.simrel.build.

# Note that this script will not capture those in the "calisto-dev"
# group who have never contributed to the "git repo".

# Note too, that in future, it will continue to "re-find" people who hae been removed already,
# from callisto-dev. May want to adjust "authors" to be "only authors since November, 2013,
# since any prior to that will have been "dealt with" already? And/or find a better way
# to automate this "git listing" with the "listing" of ids from callisto-dev list.

allauthors() { git shortlog -sen | cut -s -f2 | sort; }
authors() { git shortlog -sn | cut -s -f2 | sort; }
lastyear() { git shortlog -sn --since="1 year ago" | cut -s -f2 | sort; }

# allauthors is used, instead of authors, to write a temporary file, allauthors.txt,
# that can be used to improve the .mailmap file,
# which is in root of repository, and makes sure the mistakes or changes
# in names or emails get mapped to just one name and email. Having a good
# .mailmap file improves the "final output" quite a bit. Otherwise, the report may show
# same person on both active and inactive lists, and other anomilies, depending on which id they
# used for the commit.

# get "date of run" for putting in files.
now=$( date --utc +%s )

echo -e "\n\t\tReport as of  $( date --utc -d @$now ) \n" >allauthors.txt
allauthors >> allauthors.txt


filename=committerList.txt
echo -e "\n\t\tReport as of  $( date --utc -d @$now ) \n" >$filename
echo "Active during last year" >>$filename
echo "=======================" >>$filename
lastyear >>$filename
echo >>$filename
echo "Inactive during last year" >>$filename
echo "=========================" >>$filename

comm -13 <(lastyear) <(authors) >>$filename
echo -e "\n\t\tOutput written to $filename"

