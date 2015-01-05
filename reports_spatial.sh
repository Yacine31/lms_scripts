#!/bin/bash

# Inclusion des fonctions
REP_COURANT="$HOME/lms_scripts"
. ${REP_COURANT}/fonctions.sh
. ${REP_COURANT}/fonctions_xml.sh

DEBUG=0

#-------------------------------------------------------------------------------
# Option Spatial/Locator
# en Standard Edition
#-------------------------------------------------------------------------------

export SQL="select distinct physical_server, s.host_name, s.instance_name, s.owner, banner, concat(o.parameter,' = ', o.value) as 'Spatial Installed'
from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name 
where o.host_name=v.host_name and o.instance_name=v.instance_name
and o.parameter='Spatial'
and s.host_name=v.host_name and s.instance_name=v.instance_name
and count_nbr not in ('0','-942') 
and owner not in ('', 'SYS', 'SYSTEM')
and locate('Enterprise', banner) = 0
order by physical_server, s.host_name, s.instance_name, s.owner"

RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
if [ "$RESULT" != "" ]; then

	echo "#-------------------------------------------------------------------------------"
	echo "# Option Spatial/Locator en Standard Edition"
	echo "#-------------------------------------------------------------------------------"
	echo "Liste des serveurs avec option SPATIAL/LOCATOR en Standard Edition"
	echo "Pour ces serveurs, vérifier si c'est SPATIAL est FALSE c'est donc LOCATOR qui est mis en oeuvre"

	if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
	mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

	export SHEET_NAME=Locator_SE
	# ouverture d'une feuille Excel
	open_xml_sheet
	# export des données
	export_to_xml
	# femeture de la feuille de calcul
	close_xml_sheet

fi

#-------------------------------------------------------------------------------
# Option Spatial/Locator
# en Enterprise Edition
#-------------------------------------------------------------------------------

export SQL="select distinct physical_server, s.host_name, s.instance_name, s.owner, banner, concat(o.parameter,' = ', o.value) as 'Spatial Installed'
from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name 
where o.host_name=v.host_name and o.instance_name=v.instance_name
and o.parameter='Spatial'
and s.host_name=v.host_name and s.instance_name=v.instance_name
and count_nbr not in ('0','-942') 
and owner not in ('', 'SYS', 'SYSTEM')
and locate('Enterprise', banner) > 0
order by physical_server, s.host_name, s.instance_name, s.owner"

RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
if [ "$RESULT" != "" ]; then

	if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
	echo "#-------------------------------------------------------------------------------"
	echo "# Option Spatial/Locator en Enterprise Edition"
	echo "#-------------------------------------------------------------------------------"
	echo "Liste des serveurs avec option SPATIAL/LOCATOR en Enterprise Edition"
	echo "Pour ces serveurs, vérifier si c'est SPATIAL est TRUE sinon c'est donc LOCATOR qui est mis en oeuvre"
	mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

	export SHEET_NAME=Spatial_SE
	# ouverture d'une feuille Excel
	open_xml_sheet
	# export des données
	export_to_xml

	#-------------------------------------------------------------------------------
	#--------- Calcul des processeurs : OS != AIX
	#-------------------------------------------------------------------------------


	export SQL="select distinct c.physical_server, c.OS, c.Processor_Type, c.Socket, c.Cores_per_Socket,
	 '' as Total_Cores, '' as Core_Factor, '' as Proc_Oracle
	from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name 
	where o.host_name=v.host_name and o.instance_name=v.instance_name
	and o.parameter='Spatial'
	and s.host_name=v.host_name and s.instance_name=v.instance_name
	and count_nbr not in ('0','-942') 
	and owner not in ('', 'SYS', 'SYSTEM')
	and locate('Enterprise', banner) > 0
	and c.os not like '%AIX%'
	group by c.physical_server
	order by physical_server" 

	RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
	if [ "$RESULT" != "" ]; then
		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		echo "Calcul des processeurs Oracle par serveur physique (OS!=AIX) :"
		mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

		# export des données
		export_to_xml
	fi

	#-------------------------------------------------------------------------------
	#--------- Calcul des processeurs : OS == AIX
	#-------------------------------------------------------------------------------

	export SQL="select distinct 
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
	c.Core_Factor ,
	c.CPU_Oracle
	from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name 
	where o.host_name=v.host_name and o.instance_name=v.instance_name
	and o.parameter='Spatial'
	and s.host_name=v.host_name and s.instance_name=v.instance_name
	and count_nbr not in ('0','-942') 
	and owner not in ('', 'SYS', 'SYSTEM')
	and locate('Enterprise', banner) > 0
	and c.os like '%AIX%'
	order by physical_server" 

	RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
	if [ "$RESULT" != "" ]; then
		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL"

		# export des données
		export_to_xml

		echo "Calcul des processeurs Oracle par serveur physique (OS=AIX) :"

		export SQL="
		drop table  if exists proc_oracle;

		create table proc_oracle as
		select
		    r.physical_server,
		    sum(r.CPU_Oracle) 'Total_Proc',
		    r.Core_Factor,
		    r.Active_Physical_CPUs,
		    if (sum(r.CPU_Oracle)<r.Active_Physical_CPUs,sum(r.CPU_Oracle),r.Active_Physical_CPUs) 'Proc_Oracle_Calcules'
		from
		(select distinct physical_server, s.host_name, Partition_Mode,
		Partition_Type, Active_Physical_CPUs, Entitled_Capacity, Active_CPUs_in_Pool, Online_Virtual_CPUs, Processor_Type,
		Core_Count, Core_Factor, CPU_Oracle
		from $tVersion v, $tVoption o, $tSpatial s left join $tCPU c on s.host_name=c.host_name 
		where o.host_name=v.host_name and o.instance_name=v.instance_name
		and o.parameter='Spatial'
		and s.host_name=v.host_name and s.instance_name=v.instance_name
		and count_nbr not in ('0','-942') 
		and owner not in ('', 'SYS', 'SYSTEM')
		and locate('Enterprise', banner) > 0
		and c.os like '%AIX%'
		order by physical_server) r
		group by physical_server;

		select * from proc_oracle;"

		# export des données
		export_to_xml


		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		mysql -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL" 

		export SQL="select sum(Proc_Oracle_Calcules) from proc_oracle"

		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		echo "Somme des processeurs Oracle pour les serveurs AIX :" $(mysql -s -u${MYSQL_USER} -p${MYSQL_PWD} --local-infile --database=${MYSQL_DB} -e "$SQL")

		# export des données
		export_to_xml
	fi
	# femeture de la feuille de calcul
	close_xml_sheet

fi 