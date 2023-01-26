#!/bin/bash
# este script va a crear una web de nginx que especifiquemos
# junto con su .conf, con su carpeta, permisos, hosts y toda la pesca


# declaración de constantes:
sites_available=/etc/nginx/sites-available
sites_enabled=/etc/nginx/sites-enabled/
www_root=/var/www
log_folder=/var/log/nginx
debug=0

# La función mostrará estado de ejecución de un comando 
# $1 = comando a ejecutar
# $2 = texto a mostrar
function procesar()
{
    ejec="$1"
    texto="$2"

    # si estamos en modo debug, nos imprime por la pantalla el comando a ejecutar
    if [ $debug -ne 0 ]; then echo \$ejec="$ejec"; fi

    # Imprimimos por la pantalla el texto de ejecución, tipo "Ejecutando..."
    echo -n "${texto}..."
    
    # con eval intentamos ejecutar el comando. Usamos eval para casos cuando el comando lleva tubería
    if eval "$ejec"; then
        # si la ejecución ha sido correcta, reemplazamos el mensaje anterior por otro, tipo "Ejecutando [ OK ]"
        echo -e "\r${texto} [ $(tput setaf 2)OK$(tput sgr0) ]" 
        # la función devuelve 0
        return 0
    else
        err="$?"
        # si la ejecución ha resultado en error, reemplazamos el mensaje de ejecución por "Ejecutando [ ERROR ]"
        echo -e "\r${texto} [ $(tput setaf 1)ERROR $err$(tput sgr0) ]" 
        # devolvemos el código de error producido al hilo de ejecución principal.
        return $err
    fi
}


# solicitar derechos de administrador
# solicita permisos de sudo al usuario. 
sudo -p 'Por favor, introduce tu clave de usuario: ' echo -ne '\r'

# pedir al usuario introducir la web
read -p "Introduce la página web que deseas crear:" web_nueva
conf=$sites_available/$web_nueva
carpeta=$www_root/$web_nueva


# crear archivo conf

procesar "sudo touch $conf" "Creando archivo de configuración $conf"
sudo echo "server {
    listen 80;
    root $carpeta;
    index index.html;
    server_name $web_nueva;

    location / {
        try_files \$uri \$uri/ =404;
    }
    error_log $log_folder/error_${web_nueva}.log;
    access_log $log_folder/access_${web_nueva}.log;
}" | sudo tee -a "$conf" > /dev/null

# crear carpeta
procesar "sudo mkdir $carpeta" "Creando carpeta $carpeta"


# establecer permisos de carpeta
procesar "sudo chown -R www-data:www-data $carpeta" "estableciendo permisos de la carpeta"

# crear en la carpeta un index.html por defecto de ejemplo

procesar "sudo touch $carpeta/index.html" "Creando archivo $carpeta/index.html"
sudo echo "Bienvenido a ${web_nueva}!" | sudo tee -a "$carpeta/index.html" > /dev/null

# crear enlace simbólico en sites-enabled
procesar "sudo ln -s $conf $sites_enabled" "Creando enlace simbólico en $sites_enabled"

# meter en archivo hosts una entrada con la nueva web
procesar "sudo echo 127.0.0.1 $web_nueva | sudo tee -a /etc/hosts > /dev/null" "Cambiando archivo hosts"

# reiniciar servicio web
procesar "sudo nginx -s reload" "recargando servicio nginx"

# hacemos curl a nuestra web para sentirnos guay
echo "Prueba de curl a $web_nueva"
sleep 1
curl $web_nueva
