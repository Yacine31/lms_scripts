<?php
// TODO :
// au lieu de faire print, insérer dans une table mysql
// ensuite faire des selects pour afficher les infos ou générer un fichier xml
// penser à afficher les serveurs dans un cluster pour voir si les scripts ont été exécutés sur
// tous les serveurs
//

function ListIn($dir, $prefix = '') {
  $dir = rtrim($dir, '\\/');
  $result = array();

    foreach (array_diff(scandir($dir), array('..', '.')) as $f) {
      if (is_dir("$dir/$f")) {
          $result = array_merge($result, ListIn("$dir/$f", "$prefix$f/"));
        } else {
          $result[] = $prefix.$f;
        }
     }

  return $result;
}


// variables
$wls_home="";
$host_name="";
$product_name = "";
$product_version = "";

$files = ListIn('.');
foreach($files as $file)
{
    // parcourir tous les fichiers a la recherche de registry.xml
    // ensuite extraire les informations suivante : Hostname, Home ou est installé Weblo, Nom du produit, Version
    // si une installation de Java est présente, alors le nom est affiché
    if( strstr($file, '/registry.xml' ))
    {
        echo "Nom de fichier = " . $file . "\n";
        $xml = simplexml_load_file($file);

        foreach($xml->host as $host)
        {
            print "========\n";

            print "Filename;Hostname;Home;Product name;Version;InstallTime\n";
            foreach($host->product->release->component as $component)
            {
                if ($component['name'] == 'WebLogic Server')
                {
                    print $file . ";" ;
                    print $host['name'] . ";" ;
                    print $host['home'] . ";" ;
                    print $component['name'] . ";" ;
                    print $component['version'] . ";" ;
                    print $host->product->release['InstallTime'] . ";" ;
                    print $host->product->release['InstallDir'] . ";" ;
                    print "\n";
                }
            }
            print "========\n";
        }

    }
}
?>

