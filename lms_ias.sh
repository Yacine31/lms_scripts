# extraction des donnees depuis les fichiers opmn.xml
# fichier de sortie
OUTPUT_FILE=opmn.xml.csv

# affichage du header
echo "SERVER_NAME;INSTANCE_NAME;PROCESS_TYPE;MODULE_ID;P_STATUS" > $OUTPUT_FILE

# initialisation et export des variables
export SERVER_NAME INSTANCE_NAME PROCESS_TYPE MODULE_ID P_STATUS

# on cherche tous les fichiers Home??.opmn.xml
find -type f -iname "Home*.opmn.xml" | while read XML_FILE
do
  echo "Traitement du fichier : " $XML_FILE
  # on va extraire le nom de l'instance
  INSTANCE_NAME=`cat $XML_FILE | grep '<ias-instance' | sed 's/[<>"]//g' | awk '{print $2}' | cut -d'=' -f2-`
  # ensuite le nom du serveur
  SERVER_NAME=`echo $INSTANCE_NAME | cut -d'.' -f2-`
  # process-type, module-id et status
  cat $XML_FILE | grep 'module-id=' | while read XML_LINE
  do
    PROCESS_TYPE=`echo $XML_LINE | sed 's/[<>"]//g' | awk '{print $2}' | cut -d'=' -f2-`
    MODULE_ID=`echo $XML_LINE | sed 's/[<>"]//g' | awk '{print $3}' | cut -d'=' -f2-`
    P_STATUS=`echo $XML_LINE | sed 's/[<>"]//g' | awk '{print $4}' | cut -d'=' -f2-`
    echo "$SERVER_NAME;$INSTANCE_NAME;$PROCESS_TYPE;$MODULE_ID;$P_STATUS" >> $OUTPUT_FILE
  done
done
echo "resultat dans le fichier de sortie : $OUTPUT_FILE"

