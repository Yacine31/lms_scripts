#!/bin/bash

# Inclusion des fonctions
REP_COURANT="$HOME/lms_scripts"
. ${REP_COURANT}/fonctions.sh
. ${REP_COURANT}/fonctions_xml.sh

DEBUG=0

#-------------------------------------------------------------------------------
# Option Data Mining
#-------------------------------------------------------------------------------

export SQL="select distinct physical_server, d.host_name, d.instance_name, d.owner, model_name, banner
from $tVersion v, $tDataMining d left join $tCPU c on d.host_name=c.host_name 
where d.host_name=v.host_name and d.instance_name=v.instance_name
and count_nbr not in ('0','-942') 
and model_name <> ''
-- and locate('Enterprise', banner) > 0
order by physical_server, d.host_name, d.instance_name, d.owner
"

RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
if [ "$RESULT" != "" ]; then
	if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
	echo "#-------------------------------------------------------------------------------"
	echo "# Option Data Mining"
	echo "#-------------------------------------------------------------------------------"
	mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL"

	export SHEET_NAME=DataMining
	# ouverture d'une feuille Excel
	open_xml_sheet
	# export des données
	export_to_xml

	#-------------------------------------------------------------------------------
	#--------- Calcul des processeurs : OS != AIX
	#-------------------------------------------------------------------------------

	export SQL="select distinct c.physical_server, c.OS, c.Processor_Type, c.Socket, c.Cores_per_Socket,
	 '' as Total_Cores, '' as Core_Factor, '' as Proc_Oracle
	from $tVersion v, $tDataMining d left join $tCPU c on d.host_name=c.host_name 
	where d.host_name=v.host_name and d.instance_name=v.instance_name
	and count_nbr not in ('0','-942') 
	and model_name <> ''
	-- and locate('Enterprise', banner) > 0
	and c.os not like '%AIX%'
	group by c.physical_server
	order by physical_server"

	RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
	if [ "$RESULT" != "" ]; then
		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		echo "Calcul des processeurs Oracle par serveur physique (OS!=AIX) :"
		mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL"

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
	from $tVersion v, $tDataMining d left join $tCPU c on d.host_name=c.host_name 
	where d.host_name=v.host_name and d.instance_name=v.instance_name
	and count_nbr not in ('0','-942') 
	and model_name <> ''
	-- and locate('Enterprise', banner) > 0
	and c.os like '%AIX%'
	order by physical_server"


	RESULT=$(mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")
	if [ "$RESULT" != "" ]; then
		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL"

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
		(select distinct physical_server, d.host_name, Partition_Mode,
		Partition_Type, Active_Physical_CPUs, Entitled_Capacity, Active_CPUs_in_Pool, Online_Virtual_CPUs, Processor_Type,
		Core_Count, Core_Factor, CPU_Oracle
		from $tVersion v, $tDataMining d left join $tCPU c on d.host_name=c.host_name 
		where d.host_name=v.host_name and d.instance_name=v.instance_name
		and count_nbr not in ('0','-942') 
		and model_name <> ''
		-- and locate('Enterprise', banner) > 0
		and c.os like '%AIX%'
		order by physical_server) r
		group by physical_server;

		select * from proc_oracle;"

		# export des données
		export_to_xml


		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		mysql -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL" 

		export SQL="select sum(Proc_Oracle_Calcules) from proc_oracle"

		if [ "$DEBUG" == "1" ]; then echo "[DEBUG] - $SQL"; fi
		echo "Somme des processeurs Oracle pour les serveurs AIX :" $(mysql -s -u${MYSQL_USER} -p${MYSQL_PWD} --database=${MYSQL_DB} -e "$SQL")

		# export des données
		export_to_xml
	fi
	# femeture de la feuille de calcul
	close_xml_sheet

fi