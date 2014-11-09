#!/usr/bin/env bash

# Utility to get "real names" from group membership ids -- callisto-dev, by default.
# Note, this utility makes use of "finger" ... probably not as exact as
# using Eclipse Foundations LDAP database, but as far as I know that is not "accessible".

# This script must be ran from a "shell" on build.eclipse.org.

GRP=$1
if [[ -z "${GRP}" ]]
then
  GRP=callisto-dev
fi

echo -e "\n\tProcessing group ${GRP}\n"

# remove files, if they already exist, from previous run
rm ${GRP}.tmp.txt ${GRP}.txt 2>/dev/null

userids=$( getent group ${GRP} )
#echo -e "DEBUG: userids:\n $userids"

# strip off the initial group name/number
userids=${userids##*:}
#echo -e "DEBUG: userids:\n$userids"

# temporarily use comma for the "system seperator", for the for loop
# (works better than changing to spaces, for some reason?
# Perhaps spaces need to be stripped, after words?
saveIFS="$IFS"
IFS=,
#userids=$(echo $userids | tr ',' ' ')
#echo -e "DEBUG: userids:\n $userids"
#exit

for userid in $userids;
do
  #echo -e "DEBUG: userid\n $userid"
  data=$( finger $userid )
  # basic logic of following is to get the one line (first line) that has "Login: "and "Name: " in it,
  # plus just as well skip those with "genie", those are "technical entries" that must stay.
  # Then expand tabs to spaces, then compress all multiples occurances of space,
  # Then use cut to get the data we want, then we use awk, so names come first, followed by login id.
  echo $data | awk '!/genie/ && /Name: /' | expand | tr -s ' ' | cut -d ' '  -s -f 2,4- | awk '{for(i=2;i<=(NF-1);i++) {printf $i " "}; {printf "%-20s", $NF } ; {printf "%s\n", $1} }' >>${GRP}.tmp.txt
done
IFS=$saveIFS

cat ${GRP}.tmp.txt | sort > ${GRP}.txt
# cleanup tmp file
rm ${GRP}.tmp.txt

echo -e "\n\t Output is in ${GRP}.txt"
