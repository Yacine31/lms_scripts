#!/bin/bash

#-------------------------------------------------------------------------------
# Historique
#-------------------------------------------------------------------------------
# 08/11/2017 - suppression de la détection de SPATAIL en SE
#            - correction de la détection sur EE et de la sortie xml
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Principe :
#-------------------------------------------------------------------------------
# Le script consulte la table xxx_spatial pour extraire les lignes qui ont un COUNT_NBR > 0
# Ensuite il fait les jointures avec les tables xxx_version pour prendre uniquement les bases EE
# L'étape suivante est de faire le calcul du nombre de processeurs en faisant la jointure avec 
# la table xxx_lms_cpu.
#-------------------------------------------------------------------------------


# Inclusion des fonctions
. ${SCRIPTS_DIR}/fonctions.sh
. ${SCRIPTS_DIR}/fonctions_xml.sh

DEBUG=0

#-------------------------------------------------------------------------------
# LOCATORE EN Standard Edition
#-------------------------------------------------------------------------------

# on execute une requete pour sortie les bases en Standard Edition
# On validera avec le client que c'est LOCATORE qui est exécuté et non Spatial
export SQL="select 
    s.host_name, 
    s.instance_name, 
    s.count_nbr, 
    s.sdo_owner, 
    s.sdo_table_name, 
    s.sdo_column_name,
    v.banner 
from 
    $tSpatial s, $tVersion v
where 
    s.host_name=v.host_name and 
    s.instance_name=v.instance_name and
    locate('Enterprise', banner) = 0 and
    count_nbr not in ('0','-942') 
order by s.host_name, s.instance_name;
"
echo $SQL

mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL"

RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
if [ "$RESULT" != "" ]; then
        if [ "$DEBUG" == "1" ]; then echo "[DEBUG $0] - $SQL"; fi
        echo $YELLOW
        echo "#-------------------------------------------------------------------------------"
        echo "# Liste des base en STANDARD EDITION avec LOCATOR"
        echo "#-------------------------------------------------------------------------------"
        echo $GREEN
        echo "Liste des serveurs avec LOCATOR en Standard Edition :"
        echo "Valider avec le client que c'est LOCATOR qui est utilisé"
        echo $NOCOLOR

        #-------------------------------------------------------------------------------
        # affichage du détail de l'utilisation de LOCATOR par instance
        #-------------------------------------------------------------------------------
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

        export SHEET_NAME=Locator_SE
        # ouverture d'une feuille Excel
        open_xml_sheet
        # export des données
        export_to_xml
        close_xml_sheet
fi

#-------------------------------------------------------------------------------
# Option Spatial
# en Enterprise Edition
#-------------------------------------------------------------------------------

export SQL="select s.HOST_NAME, s.INSTANCE_NAME, s.COUNT_NBR, s.SDO_OWNER, s.SDO_TABLE_NAME, s.SDO_COLUMN_NAME 
from $tSpatial s, $tVersion v
where s.COUNT_NBR>0 
and s.HOST_NAME=v.HOST_NAME and s.INSTANCE_NAME=v.INSTANCE_NAME
and locate('Enterprise', BANNER) > 0
order by s.HOST_NAME, s.INSTANCE_NAME;"

# RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
if [ "$RESULT" != "" ]; then
        if [ "$DEBUG" == "1" ]; then echo "[DEBUG $0] - $SQL"; fi
        echo $YELLOW
        echo "#-------------------------------------------------------------------------------"
        echo "# Option Spatial en Enterprise Edition"
        echo "#-------------------------------------------------------------------------------"
        echo $GREEN
        echo "Liste des serveurs avec option SPATIAL en Enterprise Edition"
        echo "Si COUNT est > 0 alors l'option SPATIAL est utilisée"
        echo $NOCOLOR

        #-------------------------------------------------------------------------------
        # affichage du détail de l'utilisation de SPATIAL par instance
        #-------------------------------------------------------------------------------
        mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

        export SHEET_NAME=Spatial_EE
        # ouverture d'une feuille Excel
        open_xml_sheet
        # export des données
        export_to_xml

        #-------------------------------------------------------------------------------
        # détail des serveurs qui utilisent SPATAIL
        #-------------------------------------------------------------------------------
        export SQL="select distinct physical_server, s.host_name, s.instance_name, banner, concat(o.parameter,' = ', o.value) as 'Spatial Installed'
        from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name
        where o.host_name=v.host_name and o.instance_name=v.instance_name
        and o.parameter='Spatial'
        and s.host_name=v.host_name and s.instance_name=v.instance_name
        and count_nbr not in ('0','-942')
        and locate('Enterprise', banner) > 0
        order by physical_server, s.host_name, s.instance_name"

        mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"
        # export des données
        export_to_xml

        #-------------------------------------------------------------------------------
        #--------- Calcul des processeurs : OS != AIX
        #-------------------------------------------------------------------------------


        export SQL="select distinct c.physical_server, c.OS, c.Processor_Type, c.Socket, c.Cores_per_Socket,
         c.Total_Cores, Core_Factor, Total_Cores*Core_Factor as Proc_Oracle
        from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name
        where o.host_name=v.host_name and o.instance_name=v.instance_name
        and o.parameter='Spatial'
        and s.host_name=v.host_name and s.instance_name=v.instance_name
        and count_nbr not in ('0','-942')
        and locate('Enterprise', banner) > 0
        and c.os not like '%AIX%'
        group by c.physical_server
        order by physical_server"

        export SELECT_NON_AIX="distinct c.physical_server, c.OS, c.Processor_Type, c.Socket, c.Cores_per_Socket, c.Total_Cores, Core_Factor, Total_Cores*Core_Factor as Proc_Oracle"

        export FROM="$tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name"
        export WHERE="o.host_name=v.host_name and o.instance_name=v.instance_name
        and o.parameter='Spatial'
        and s.host_name=v.host_name and s.instance_name=v.instance_name
        and count_nbr not in ('0','-942')
        and locate('Enterprise', banner) > 0
        and c.os not like '%AIX%'"
        export GROUPBY="c.physical_server order by physical_server"

        SQL="select $SELECT_NON_AIX from $FROM where $WHERE group by $GROUPBY"
        if [ "$DEBUG" == "1" ]; then echo "[DEBUG - $0 ] - $SQL"; fi

        RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
        if [ "$RESULT" != "" ]; then
                # affichage du tableau pour le calcul du nombre de processeur
                print_proc_oracle $SELECT_NON_AIX'|'$FROM'|'$WHERE

                # export des données
                export_to_xml
        fi

        #-------------------------------------------------------------------------------
        #--------- Calcul des processeurs : OS == AIX
        #-------------------------------------------------------------------------------

        export SELECT=" distinct
        c.physical_server 'Physical Server',
        c.Host_Name 'Host Name',
        c.OS,
        c.Processor_Type 'Proc Type',
        c.Partition_Type 'Partition Type',
        c.Partition_Mode 'Partition Mode',
        c.Entitled_Capacity 'EC',
        c.Active_CPUs_in_Pool 'ACiP',
        c.Online_Virtual_CPUs 'OVC',
        c.Active_Physical_CPUs 'APC',
        c.Core_Count ,
        c.Core_Factor"
        export FROM=" $tVersion a, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name "
        export WHERE=" o.host_name=a.host_name and o.instance_name=a.instance_name
        and o.parameter='Spatial'
        and s.host_name=a.host_name and s.instance_name=a.instance_name
        and count_nbr not in ('0','-942')
    
        and locate('Enterprise', banner) > 0
        and c.os like '%AIX%'"

        export SQL="select $SELECT from $FROM where $WHERE order by physical_server"

        RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
        if [ "$RESULT" != "" ]; then
                if [ "$DEBUG" == "1" ]; then echo "[DEBUG $0] - $SQL"; fi
                mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

                # export des données
                export_to_xml

                print_proc_oracle_aix $SELECT'|'$FROM'|'$WHERE
        fi
        # femeture de la feuille de calcul
        close_xml_sheet
fi

