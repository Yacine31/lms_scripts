#!/bin/bash
# interroger les tables pour trouver les infos
# 19/05/2014 - le script est appelé depuis extract.sh
# 20/05/2014 - séparation des affichages pour AIX : les colonnes ne sont pas les mêmes
# 22/05/2014 - modification des jointures (left join) pour prendre en compte les noms des serveurs
#              même si les infos serveurs ne sont pas présentes.
# 23/05/2014 - ajout de MDSYS aux compte exclus du partitioning
#              ajout des listing des bases et serveur par edition

# MYSQL_ARGS="--defaults-file=/etc/mysql/debian.cnf"
DB="test"
PROJECT_NAME="$1"

[ "$PROJECT_NAME" = "" ] && echo "Syntax: $0 PROJECT_NAME" && exit 1

tDB=$PROJECT_NAME"_db"      # table qui contient les donnees db
tCPU=$PROJECT_NAME"_cpu"    # table qui contient les donnees des serveurs
tSegments=$PROJECT_NAME"_segments"  # table qui contient les objets partitionés
tDbaFeature=$PROJECT_NAME"_dba_feature"  # table qui contient les options et packs utilisés
tVersion=$PROJECT_NAME"_version"  # table qui contient les versions
tOLAP=$PROJECT_NAME"_olap"  # table qui contient les objets OLAP/Analytic Workspaces


# Fontions diverses
function fnPrintLegende {
echo '---------------------------------'
echo '  Part Nbr = Partition Number' 
echo ' Part Type = Partition Type'
echo ' Part Mode = Partition Mode'
echo '        EC = Entitled Capacity'
echo '   Act CPU = Active CPUs in Pool'
echo '    OV CPU = Online Virtual CPUs'
echo '---------------------------------'
}


echo "Liste des serveurs sans base de données"
mysql -uroot -proot --local-infile --database=$DB -e "
select Host_Name, os, Marque, Model, Processor_Type 
from $tCPU where host_name not in (SELECT Host_Name FROM $tDB)
order by Host_Name;
"

echo "Liste des serveur sans le résultat de lms_cpuq.sh"

mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct Host_Name FROM $tDB where Host_Name not in (select Host_Name from $tCPU) 
order by Host_Name;
"

echo "Liste des serveurs en Standard Edition"

mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Machine_Serial_Number, v.Host_Name, cpu.Marque, cpu.Model, cpu.Processor_Type, left(cpu.OS, 25) OS, cpu.Socket   
FROM $tVersion v left join $tCPU cpu 
on cpu.Host_Name=v.Host_Name 
where v.banner like '%Oracle%' and v.banner not like '%Enterprise%'
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"

echo "Liste des base et serveurs en Standard Edition"

mysql -uroot -proot --local-infile --database=$DB -e "
select Host_Name, Instance_Name, BANNER 
from $tVersion where banner not like '%Enterprise%' 
order by Host_Name, Instance_Name, BANNER;
"

echo "Liste des serveurs en Enterprise Edition"

mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct db.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS, cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores 
FROM $tDB db left join $tCPU cpu 
on cpu.Host_Name=db.Host_Name
where db.DB_Edition='Enterprise' 
and cpu.os not like '%AIX%' 
order by cpu.Marque, cpu.Host_Name, cpu.os;
"


echo "--> Les serveur AIX avec le même numéro de série sont sur le même chassis : à valider avec le client"

mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name,  cpu.Model, left(cpu.OS, 25) OS, cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores, 
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
-- FROM $tDB db left join $tCPU cpu 
-- on cpu.Host_Name=db.Host_Name
-- where db.DB_Edition='Enterprise' and cpu.os like '%AIX%' 
-- order by cpu.Marque, cpu.Host_Name, cpu.os;
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tDB db left join $tCPU cpu
on cpu.Host_Name=db.Host_Name
where db.DB_Edition='Enterprise' and cpu.os like '%AIX%'
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"

fnPrintLegende 

echo "Liste des base et serveurs en Enterprise Edition"

mysql -uroot -proot --local-infile --database=$DB -e "
select Host_Name, Instance_Name, BANNER 
from $tVersion where banner like '%Enterprise%' 
order by Host_Name, Instance_Name, BANNER;
"

echo "Liste des serveurs avec option RAC en Enterprise Edition"

mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS, cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores 
FROM $tDB db left join $tCPU cpu 
on cpu.Host_Name=db.Host_Name
where db.DB_Edition='Enterprise' and db.v_opt_rac not in ('FALSE','') and cpu.os not like '%AIX%'
order by cpu.Marque, cpu.os, cpu.Host_Name;
"
mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS, cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tDB db left join $tCPU cpu 
on cpu.Host_Name=db.Host_Name
where db.DB_Edition='Enterprise' and db.v_opt_rac not in ('FALSE','') and cpu.os like '%AIX%'
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"

echo "Liste des serveurs avec option PARTITIONING en Enterprise Edition"
export SQL_NOT_IN="('SYS','SYSTEM','SYSMAN','MDSYS')"
echo "Les comptes $SQL_NOT_IN ne sont pas pris en compte"

# jointure avec la table des objets partionnés
# serveurs non AIX
mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct seg.Host_Name, cpu.Marque, cpu.Model, 
-- left(cpu.OS, 25) OS, 
cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket
-- ,  cpu.Total_Cores
FROM $tCPU cpu, $tSegments seg, $tDB db
where cpu.Host_Name=db.Host_Name
and cpu.Host_Name=seg.Host_Name 
and db.DB_Edition='Enterprise' 
and cpu.os not like '%AIX%'
and seg.owner not in $SQL_NOT_IN 
-- and db.Partitioning!='0' 
group by seg.Host_Name, cpu.Marque, cpu.Model, cpu.OS, cpu.Processor_Type, 
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores
having count(seg.Host_Name) > 0
order by cpu.Marque, cpu.Host_Name, cpu.os
;
"

# serveurs AIX
mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct seg.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS, cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tSegments seg, $tDB db
where cpu.Host_Name=db.Host_Name
and cpu.Host_Name=seg.Host_Name 
and db.DB_Edition='Enterprise' 
and cpu.os like '%AIX%'
and seg.owner not in $SQL_NOT_IN
-- and db.Partitioning!='0' 
group by seg.Host_Name, cpu.Marque, cpu.Model, cpu.OS, cpu.Processor_Type, 
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores
having count(seg.Host_Name) > 0
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os
;
"


echo "Liste des bases avec objets partitionnés"
echo "Les comptes $SQL_NOT_IN ne sont pas pris en compte"
mysql -uroot -proot --local-infile --database=$DB -e "
select host_name, instance_name, owner,
-- segment_type, 
count(*) from $tSegments 
where owner not in $SQL_NOT_IN 
group by host_name, instance_name, owner
-- , segment_type
order by host_name, instance_name, owner
-- , segment_type
;
"


echo "Liste des serveurs avec option OLAP en Enterprise Edition"
mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and db.DB_Edition='Enterprise' and cpu.os not like '%AIX%'
and db.OLAP_Installed='TRUE' and (db.OLAP_Cubes not in ('','0','-942') or db.Analytic_Workspaces not in ('0','','-942'))
order by cpu.Marque, cpu.Host_Name, cpu.os;
"

mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and db.DB_Edition='Enterprise' and cpu.os like '%AIX%'
and db.OLAP_Installed='TRUE' and (db.OLAP_Cubes not in ('','0','-942') or db.Analytic_Workspaces not in ('0','','-942'))
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"

echo "Détail des bases avec l'option OLAP en Enterprise Edition"
mysql -uroot -proot --local-infile --database=$DB -e "
select HOST_NAME, INSTANCE_NAME, OLAP_INSTALLED, OLAP_CUBES, ANALYTIC_WORKSPACES 
from $tDB where OLAP_Installed='TRUE' and (OLAP_Cubes not in ('','0','-942') or Analytic_Workspaces not in ('0', '', '-942'))
order by HOST_NAME, INSTANCE_NAME;
"

echo "Détail des bases avec l'option OLAP en Enterprise Edition (Schéma SYS non pris en compte) :" 
mysql -uroot -proot --local-infile --database=$DB -e "
select HOST_NAME, INSTANCE_NAME, OWNER, AW_NAME, AW_NUMBER, PAGESPACES
from $tOLAP where Count_Nbr not in ('','0','-942') and Owner not in ('SYS')
order by HOST_NAME, INSTANCE_NAME, OWNER, AW_NAME;
"




echo "Liste des serveurs avec option DATAMINING en Enterprise Edition"
mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and db.DB_Edition='Enterprise' and cpu.os not like '%AIX%'
and db.v_opt_dm!=''
order by cpu.Marque, cpu.Host_Name, cpu.os;
"
mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and db.DB_Edition='Enterprise' and cpu.os like '%AIX%'
and db.v_opt_dm!=''
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"


echo "Liste des serveurs avec option SPATIAL/LOCATOR en Enterprise Edition"
mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and db.DB_Edition='Enterprise' and cpu.os not like '%AIX%'
and db.v_opt_spatial!=''
order by cpu.Marque, cpu.Host_Name, cpu.os;
"

mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and db.DB_Edition='Enterprise' and cpu.os like '%AIX%'
and db.v_opt_spatial!=''
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"



echo "Liste des serveurs qui utilisent TUNING PACK"

mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, 
-- left(cpu.OS, 25) OS,
cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket
-- , cpu.Total_Cores
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and cpu.os not like '%AIX%'
-- and db.DB_Edition='Enterprise'
and db.Tuning_Pack_Used!='0'
order by cpu.Marque, cpu.os, cpu.Host_Name;
"

mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and cpu.os like '%AIX%'
-- and db.DB_Edition='Enterprise'
and db.Tuning_Pack_Used!='0'
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"

echo "Détail des fonctionnalités utilisées de TUNING PACK"
mysql -uroot -proot --local-infile --database=$DB -e "
select Host_Name, Instance_Name, NAME, DETECTED_USAGES, LAST_USAGE_DATE
from $tDbaFeature
where name in ('SQL Access Advisor','SQL Tuning Advisor','SQL Plan Management','SQL Monitoring')
order by Host_Name, Instance_Name, NAME;
"

echo "Liste des serveurs qui utilisent DIAGNOSTICS PACK"

mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model,
-- left(cpu.OS, 25) OS,
cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket
-- ,  cpu.Total_Cores
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and cpu.os not like '%AIX%'
-- and db.DB_Edition='Enterprise'
-- and db.Tuning_Pack_Used='0' 
and db.Diag_Pack_Used!='0'
order by cpu.Marque, cpu.Host_Name, cpu.os;
"

mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and cpu.os like '%AIX%'
-- and db.DB_Edition='Enterprise'
-- and db.Tuning_Pack_Used='0'
and db.Diag_Pack_Used!='0'
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"

echo "Détail des fonctionnalités utilisées de DIAGNOSTICS PACK"
mysql -uroot -proot --local-infile --database=$DB -e "
select Host_Name, Instance_Name, NAME, DETECTED_USAGES, LAST_USAGE_DATE 
from $tDbaFeature
where name='Automatic Workload Repository'
or name='Automatic Database Diagnostic Monitor'
or name like 'AWR%'
or name like 'ADDM%'
or name='Active Session History'
or name='EM Performance Page'
order by Host_Name, Instance_Name, NAME;
"

echo "Liste des serveurs qui doivent être licenciés en DIAGNOSTICS PACK car ils utilisent TUNING PACK"
mysql -uroot -proot --local-infile --database=$DB -e "
SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, 
cpu.Processor_Type,
cpu.Socket, cpu.Cores_per_Socket
-- , cpu.Total_Cores
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and cpu.os not like '%AIX%'
-- and db.DB_Edition='Enterprise'
and db.Tuning_Pack_Used!='0'
and db.Diag_Pack_Used='0'
order by cpu.Marque, cpu.os, cpu.Host_Name;
"

mysql -uroot -proot --local-infile --database=$DB -e "
-- SELECT distinct cpu.Host_Name, cpu.Marque, cpu.Model, left(cpu.OS, 25) OS,cpu.Processor_Type,
-- cpu.Socket, cpu.Cores_per_Socket,  cpu.Total_Cores,
-- cpu.Node_Name, cpu.Partition_Name, cpu.Partition_Number,
-- cpu.Partition_Type,cpu.Partition_Mode, cpu.Entitled_Capacity, cpu.Active_CPUs_in_Pool, cpu.Online_Virtual_CPUs
SELECT distinct 
cpu.Machine_Serial_Number,
cpu.Host_Name Host,  
cpu.Model, 
left(cpu.OS, 25) OS, 
cpu.Processor_Type 'Proc Type',
cpu.Partition_Number 'Part Nbr',
cpu.Partition_Type 'Part Type',
cpu.Partition_Mode 'Part Mode', 
cpu.Entitled_Capacity 'EC', 
cpu.Active_CPUs_in_Pool 'Act CPU', 
cpu.Online_Virtual_CPUs 'OV CPU'
FROM $tCPU cpu, $tDB db
where cpu.Host_Name=db.Host_Name and cpu.os like '%AIX%'
-- and db.DB_Edition='Enterprise'
and db.Tuning_Pack_Used!='0'
and db.Diag_Pack_Used='0'
order by cpu.Machine_Serial_Number, cpu.Marque, cpu.Host_Name, cpu.os;
"





