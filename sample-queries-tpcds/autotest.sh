#!/bin/bash
DIR=$( pwd  ) #cd to this directory
SETTINGS=${DIR}/ha_testbench.settings
database="tpcds_bin_partitioned_orc_200"
source /home/ubuntu/HDTestScripts/hadoop_env.sh

function usage
{
  echo "usage: autotest.sh [-l <query-list>] [-n <first-n-queries>]"
  echo "       -l: file contains list of queries to test"
  echo "       -n: select only first n queries to run test"
}

# parsing parameters
listfile=""
limit=false
while [ "$1" != "" ]; do
  case $1 in
    -l | --list )            shift
                             listfile=$1
                             ;;
    -n | --number-of-query ) shift
                             limit=true
                             NoQueries=$1
                             ;;
    -h | --help )            usage
                             exit
                             ;;
    * )                      usage
                             exit 1
  esac
  shift
done

if [ -e "$listfile" ]; then
  if [ "$limit" = "true" ]; then
    QUERY_LIST=$( head -n $NoQueries $listfile )
  else
    QUERY_LIST=$( cat $listfile )
  fi
else
  echo "No query list exists!"
  if [ "$limit" = "true" ]; then
    QUERY_LIST="$( ls -lh query*.sql | awk '{print $NF}' | head -n $NoQueries )"
  else
    QUERY_LIST="$( ls -lh query*.sql | awk '{print $NF}' )"
  fi
fi

echo "List of queries for testing:"
echo "$QUERY_LIST"

# For testing script, reset query list
# QUERY_LIST="" #temporary test code

for query in ${QUERY_LIST}; do
  echo "Processing $query"
  
  if [ -e "${DIR}/${query}.settings" ]; then
    echo "This query require custom settings"
    CUSTOM_SETTINGS="${query}.settings"
  else
    CUSTOM_SETTINGS=""
  fi
  echo "Submit query $query to hive..."
  echo "Data Space before submission:" >> ${query}.log
  hadoop fs -du -h / >> ${query}.log
  echo "Starting Time: $( date )" >> ${query}.log
  if [ "$CUSTOM_SETTINGS" != "" ]; then # if there is custom settings
    time hive -i ${SETTINGS} -e "use $database; source $CUSTOM_SETTINGS; source $query;" 2>&1 | tee -a ${query}.log
  else
    time hive -i ${SETTINGS} -e "use $database; source $query;" 2>&1 | tee -a ${query}.log
  fi
  echo "Ending Time: $( date )" >> ${query}.log
  echo "Data Space after submission:" >> ${query}.log
  hadoop fs -du -h / >> ${query}.log
done
