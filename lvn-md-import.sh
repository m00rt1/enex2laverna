#!/bin/bash

#ex: ./lvn-md-import.sh ./output ./laverna-backup.zip

set -x
set -euo pipefail
DFS=$IFS
IFS=$'\n\t'
BSIFS=$IFS

SRC_DIR=$1
echo "SRC_DIR: $SRC_DIR"
ZIP_PATH=$2
echo "ZIP_PATH: $ZIP_PATH"

get_notebookid () {
  local name=$1
  name=\"$1\"
  notebook_id=`cat notebooks.json | jq -r '.[] | select(.name=='$name') .id'`
  echo "nbid get $notebook_id"
}

create_uuid () {
  uuid=`uuidgen`
  jq .[].id laverna-backups/notes-db/notebooks.json > taken
  jq .[].id laverna-backups/notes-db/tags.json >> taken 
  jq .id laverna-backups/notes-db/notes/*.json >> taken
  set +e
  grep $uuid taken
  gr=$?
  set -e
  while [ $gr -eq 0 ]; do
    uuid=`uuidgen`
    set +e
    grep $uuid taken
    gr=$?
    set -e
  done
  echo $uuid >> taken
}

create_notebook ()  {
  local nb_name="$1"
  index=$2
  index=$((index+1)) 
  total=$3
  echo $nd
  echo "($index/$total) creating notebook named : $nb_name"
  create_uuid
  nb_id=$uuid
  cnb=`jq . notebooks.json`
  echo $cnb
  declare orders
  orders+=( "id" )
  orders+=( "type" )
  #orders+=( "count" )
  #orders+=( "trash" )
  #orders+=( "created" )
  #orders+=( "updated" )
  #orders+=( "encryptedData" )
  orders+=( "name" )
  declare -A values
  values=( ["id"]=$nb_id 
  ["type"]="notebooks"
  #["count"]=0
  #["trash"]=0
  #["created"]=$nd
  #["updated"]=$nd
  #["encryptedData"]="sedder"
  ["name"]=$nb_name
)
  local json="{}"
  for v in "${!orders[@]}"
  do
    jsk=${orders["$v"]}
    jsv=${values[${orders["$v"]}]}
    jse="{\"$jsk\": \"$jsv\"}"
    json=`jq -n "$json + $jse"`
  done

  cnb=`jq -n ["$cnb , $json"] | jq flatten `
  echo $cnb
  echo $cnb > notebooks.json
} 

create_lvn_note ()  {
  mkdir -p json
  local note_name=${1%.*}
  echo $note_name
  local nb_name=$4
  local nb_id=$6
  local index=$2
  index=$((index+1)) 
  local total=$3
  local note_id=$5
  echo $nd
  echo "($index/$total) creating note named : $note_name"
  unset values  
  local json="{}"	
  enc=\"[]\"
	
  #echo $enc
  declare orders
  orders+=( "id" )
  orders+=( "type" )
  #orders+=( "taskAll" )
  #orders+=( "taskCompleted" )
  #orders+=( "created" )
  #orders+=( "updated" )
  orders+=( "notebookId" )
  #orders+=( "isFavorite" )
  #orders+=( "trash" )
  #orders+=( "files" )
  #orders+=( "encryptedData" )
  orders+=( "title" )
  #orders+=( "tags" )
  unname=`echo "$note_name" | sed "s/\"/'/g"`
  echo $note_name
  echo $unname
  declare -A values
  values=( ["id"]=$note_id 
  ["type"]="notes"
  #["taskAll"]=0
  #["taskCompleted"]=0
  #["created"]=$nd
  #["updated"]=$nd
  ["notebookId"]=$nb_id
  #["isFavorite"]=0
  #["trash"]=0
  #["files"]=[]
  #["encryptedData"]="sedder"
  ["title"]=$unname
  #["tags"]=[]
)
  el="${values["title"]}"
  local i=0
  pos=$(( ${#values[*]} - 1 ))
  for v in "${!orders[@]}"
  do
    jsk=${orders["$v"]}
    jsv=${values[${orders["$v"]}]}
    jse="{\"$jsk\": \"$jsv\"}"
    json=`jq -n "$json + $jse"`
  done
  jq -n "$json" > "json/${note_id}.json"
  mkdir -p md
  if [ "$note_name" == "" ];then
    echo "WARN: Skipping empty node name..."
    continue
  fi
  cp $SRC_DIR/"${note_name}.md" md/${note_id}.md
  jq -n "$json" > "json/${note_id}.json"
} 

cp -v $ZIP_PATH{,.bak}
unzip $ZIP_PATH

notesjson=`ls -1 laverna-backups/notes-db/notes/*json`
min=""
max=0
for i in $notesjson
do
  echo "Handling note $i"
	
  cr=`jq .created $i`
  if [ -z $min ]
  then
    min=$cr
  fi
  if [ $cr -lt $min ]
  then
    min=$cr
  fi
  if [ $cr -gt $max ]
  then
    max=$cr
  fi
done
echo "$min - $max"

nd=$((min -1))
nd=$min
echo $nd

cp laverna-backups/notes-db/notebooks.json .
nb_name="import"
echo "nb_name $nb_name"
create_notebook "$nb_name" 1 999

OLDIFS=$IFS
IFS=$'\n'

fileArray=($(find $SRC_DIR/ -type f -printf "%f\n"))

IFS=$OLDIFS
tfLen=${#fileArray[@]}

for (( j=0; j<$tfLen; j++ ))
do
  get_notebookid $nb_name
  note_name="${fileArray[$j]}"
  create_uuid
  note_id=$uuid
  create_lvn_note "$note_name" $j $tfLen $nb_name $note_id $notebook_id
done

echo "creating zip"
mkdir -p to-import/laverna-backups/notes-db/notes/
cp laverna-backups/notes-db/configs.json to-import/laverna-backups/notes-db/
cp notebooks.json to-import/laverna-backups/notes-db/
cp laverna-backups/notes-db/tags.json to-import/laverna-backups/notes-db/
mv json/* to-import/laverna-backups/notes-db/notes/
mv md/* to-import/laverna-backups/notes-db/notes/
cd to-import
zip -qr $ZIP_PATH laverna-backups
cd ..
echo "cleaning files"
rm -fR laverna-backups
rm -fR to-import/laverna-backups
rm -fR json
rm -fR md
echo "ok your zip is now ready to import"
