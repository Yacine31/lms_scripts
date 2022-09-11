# 27/10/2021 - Création
# 
# extraire les infos cpu à partir des résultats de la commande dmidecode de Linux
#
#

find -type f -iname "*$1*-ct_cpuq.txt" | while read f; do
	nb_processor=$(cat $f | grep 'processor' | wc -l)
	nb_threads=$(cat $f | grep 'core id' | wc -l)
	nb_sockets=$(cat $f | grep 'physical id' | sort -u | wc -l)
	nb_core_par_socket=$(cat $f | grep 'core id' | sort -u | wc -l)
	nb_cpu_core=$(cat $f | grep 'cpu cores' | sort -u | cut -d: -f2) 
	echo "$f == nb_sockets : $nb_sockets, nb_core_par_socket : $nb_core_par_socket, total_vcpu : $nb_processor"
done
