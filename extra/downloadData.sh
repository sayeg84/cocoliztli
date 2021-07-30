mkdir -p ../data
cd ../data
echo "Getting raw COVID data"
wget http://datosabiertos.salud.gob.mx/gobmx/salud/datos_abiertos/datos_abiertos_covid19.zip
unzip datos_abiertos_covid19
rm datos_abiertos_covid19.zip
wget http://datosabiertos.salud.gob.mx/gobmx/salud/datos_abiertos/diccionario_datos_covid19.zip
