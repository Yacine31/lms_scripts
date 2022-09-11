echo "FileName;VirtualHostName;IASname;Version;Components;InstallType;InfrastructureUse"
find -iname "*ias.properties" | while read f; do

    dos2unix $f 1>&2 2>/dev/null
    Components=$(cat $f | grep "^Components=" | head -1 | cut -d'=' -f2)
    IASname=$(cat $f | grep "^IASname" | head -1 | cut -d'=' -f2)
    Version=$(cat $f | grep "^Version=" | head -1 | cut -d'=' -f2)
    VirtualHostName=$(cat $f | grep "^VirtualHostName=" | head -1 | cut -d'=' -f2)
    InstallType=$(cat $f | grep "^InstallType=" | head -1 | cut -d'=' -f2)
    InfrastructureUse=$(cat $f | grep "^InfrastructureUse=" | head -1 | cut -d'=' -f2)

    echo "$f;$VirtualHostName;$IASname;$Version;$Components;$InstallType;$InfrastructureUse"
done 
