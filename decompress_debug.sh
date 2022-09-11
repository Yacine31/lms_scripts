#!/bin/bash

# 11/09/2017 - Création
# 08/11/2017 - la commande find cherche uniquement les fichiers qui commencent par "LMSCollection"
# 
# le script parcour le répertoire courant à la recherche de fichiers générés
# par "LMSCollection Tools" d'Oracle, ensuite pour chaque fichier :
#   - il créé un répertoire avec le nom du serveur
#   - il décompresse le fichier dans ce répertoire
# 

line='............................................................................'
export cmd=""

# find . -maxdepth 1 -type f -iname "LMSCollection*zip" -o -iname "LMSCollection*tar" -o -iname "LMSCollection*bz2" -o -iname "LMSCollection*tar.gz" | while read f; do
# find . -maxdepth 1 -type f -iname "*zip" -o -iname "*tar" -o -iname "*bz2" -o -iname "*tar.gz" | while read f; do
find -type f -iname "debug_Collection*zip" -o -iname "debug_Collection*tar" -o -iname "debug_Collection*bz2" -o -iname "debug_Collection*tar.gz" | while read f; do
    case $f in 
        *tar)
            d=$(echo $f | sed 's/debug_Collection-//g' | sed 's/.tar//g');
            export cmd="tar xf $f -C $d 2>&1 1>/dev/null"
        ;;
        *zip)
            d=$(echo $f | sed 's/debug_Collection-//g' | sed 's/.zip//g');
            # unzip -o : ocerwrite without confirmation
            export cmd="unzip -o $f -d $d 2>&1 1>/dev/null"
        ;;
        *bz2)
            d=$(echo $f | sed 's/debug_Collection-//g' | sed 's/.tar.bz2//g');
            export cmd="tar xfj $f -C $d 2>&1 1>/dev/null"
        ;;
        *tar.gz)
            d=$(echo $f | sed 's/debug_Collection-//g' | sed 's/.tar.gz//g');
            export cmd="tar xfz $f -C $d 2>&1 1>/dev/null"
        ;;
    esac

    # execution des commandes de création du répertoire + decompression du fichier
    str1="Decompression de \"$f\""
    printf "%s %s %s\n" "$str1" "${line:${#str1}}" " dans \"$d\""
    mkdir -p $d 2>/dev/null
    eval $cmd
done

echo "=== Décompression des fichiers terminée ==="
 

