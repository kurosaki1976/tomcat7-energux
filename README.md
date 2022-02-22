# Instalando aplicación web EnerguX "Control de Portadores Energéticos" en Debian 9 Stretch

## Autor

- [Ixen Rodríguez Pérez - kurosaki1976](ixenrp1976@gmail.com)

## ¿Qué es EnerguX?

Diseñado para el control de los portadores energéticos, el software Energux constituye el producto de la Empresa de Aplicaciones Informáticas Desoft, más extendido en la geografía cubana. Energux controla de manera automática el consumo de electricidad, combustible, lubricantes, agua, gas, carbón, y proporciona además un conjunto de informes que posibilitan la toma de decisiones administrativas sobre esos recursos.

## Breve introducción a Tomcat

Apache Tomcat funciona como un contenedor de servlets desarrollado bajo el proyecto Jakarta en la Apache Software Foundation. Tomcat implementa las especificaciones de los servlets y de JavaServer Pages de Oracle Corporation.

Tomcat es un servidor Web con soporte para servlets y JSPs. No es un servidor de aplicaciones, como JBoss o JOnAS. Trae incluido el compilador Jasper, que compila JSPs convirtiéndolas en servlets. El motor de servlets de Tomcat a menudo se presenta en combinación con el servidor Web Apache. A partir de la versión 4.0, Tomcat utiliza el contenedor de servlets Catalina.

El hecho de que Tomcat fue escrito en Java, hace posible que funcione en cualquier sistema operativo que disponga de la máquina virtual Java.

## Instalar paquetes necesarios

```bash
apt install tomcat8 tomcat8-admin openjdk-8-jdk postgresql
```

Evitar futuras actualizaciones de los paquetes

```bash
apt-mark hold tomcat8 tomcat8-admin tomcat8-common openjdk-8-jdk openjdk-8-jre openjdk-8-jre-headless postgresql-client postgresql-client-common libtomcat8-java
```

## Configuración del servicio `tomcat8`

Definir usuario con acceso administrativo.

```bash
mv /etc/tomcat8/tomcat-users.xml{,.org}
nano /etc/tomcat8/tomcat-users.xml
```
```xml
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <role rolename="admin"/>
  <role rolename="manager"/>
  <role rolename="manager-gui"/>
  <role rolename="admin-gui"/>
  <role rolename="manager-script"/>
  <role rolename="manager-jmx"/>
  <user username="tomcat" password="energux" roles="admin,manager,manager-gui,admin-gui,manager-script,manager-jmx"/>
</tomcat-users>
```

Establecer límites de uso de memoria para la máquina virtual de `Java`.

```bash
nano /usr/share/tomcat8/bin/setenv.sh

JAVA_OPTS="-Xms320m -Xmx768m -XX:MaxPermSize=768m"
```

```bash
chmod +x /usr/share/tomcat8/bin/setenv.sh
```

o editar el fichero `/etc/default/tomcat8` como sigue:

```bash
mv /etc/default/tomcat8{,.org}
nano /etc/default/tomcat7

TOMCAT7_USER=tomcat8
TOMCAT7_GROUP=tomcat8
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
JAVA_OPTS="-Xms320m -Xmx768m -XX:MaxPermSize=768m"
```

> **NOTA**: Estos parámetros fueron pensados para un servidor o CT/VM corriendo con al menos 1Gb de memoria RAM.

Asignar contraseña al usuario `postgres` y crear la base de datos para EnerguX.

```bash
su - postgres -c psql
\password postgres
CREATE DATABASE energux WITH TEMPLATE template0 ENCODING 'UNICODE';
```

Reiniciar los servicios `tomcat8` y `postgresql`.

```bash
systemctl restart tomcat8 postgresql
```

## Instalar EnerguX v5

- Acceder a la URL `http://ip-fqdn-servidor:8080/manager/html` en un navegador y agregar el fichero `energux.war`.

  > **NOTA**: Se deben incrementar primero los valores de los parámetros `Max-File Size` y `Max Request Size`, definidos por defecto en 50Mb. Para ello editar el fichero `/usr/share/tomcat8-admin/manager/WEB-INF/web.xml` y en la sección `<multipart-config>` establecer valores acordes al tamaño de la aplicación a desplegar, en el caso de `energux.war`, se recomienda definir `104857600` equivalente a 100Mb en ambos parámetros.

- Definir usuario del sistema `tomcat8` como dueño del directorio de la aplicación.

```bash
chown –R tomcat8:tomcat8 /var/lib/tomcat8/webapps/energux/
```

- Completar el proceso de instalación a través de `http://ip-fqdn-servidor:8080/energux/app/instalar.jsf`.

## Actualizar hasta EnerguX v.4.0.1.5

Reemplazar el sitio por defecto con lo contenido dentro de los archivos compactados `sitio.rar` e ir ejecutando los scripts `update_4_0_x.sql` y `update_4_0_1_x.sql` en el servidor `postgresql` mediante las aplicaciones de escritorio pgAdminIII, pgAdmin4 o la consola `psql`; al finalizar reiniciar el servicio `tomcat7`.

> **NOTA**: Para trabajar con una base de datos inicalizada en cero y que contiene todos los `scripts` de actualización, se debe hacer una restaura usando el fichero [energux_2019_2_19.backup](confs/energux_2019_2_19.backup).

Abrir la dirección `http://ip-fqdn-servidor:8080/energux` acceder con el par `admin/admin` como `usuario/contraseña` y enviar el Número Serie del Producto a los especialistas de Desoft para obtener un Número de Licencia válido. Una vez obtenido, introducirlo y comenzar a explotar la aplicación.

## Modificar puertos de escucha por defecto

Si EnerguX corre en un servidor web independiente y se quiere que las peticiones de los usuarios se realicen a los puertos tradicionales (`tcp/80` y `tcp/443`) y no a los por defecto de Tomcat (`tcp/8080` y `tcp/8443`), se debe hacer lo siguiente:

* Instalar paquetes necesarios

```bash
apt install authbind
```

* Configurar el servicio `tomcat8`

```bash
nano /etc/default/tomcat8

TOMCAT7_USER=tomcat8
TOMCAT7_GROUP=tomcat8
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
JAVA_OPTS="-Xms320m -Xmx512m -XX:MaxPermSize=512m"
AUTHBIND=YES
```

Crear ficheros necesarios y asignar permisos

```bash
touch /etc/authbind/byport/{80,443}
chmod 0755 /etc/authbind/byport/*
chown tomcat8:tomcat8 /etc/authbind/byport/*
```

Crear certificado Java a partir de certificado TLS autofirmado y asignar permisos necesarios

```bash
openssl req -x509 -sha512 -days 3650 -nodes \
	-subj "/C=CU/ST=Provincia/L=Ciudad/O=Organización/OU=IT/CN=EnerguX/emailAddress=postmaster@dominio.cu/" \
	-reqexts SAN -extensions SAN -config <(cat /etc/ssl/openssl.cnf \
		<(printf "\n[SAN]\nsubjectAltName=DNS:energux.dominio.cu,DNS:localhost,IP:192.168.0.1,IP:127.0.0.1")) \
	-newkey rsa:4096 \
	-keyout EnerguX-Server.key \
	-out EnerguX-Server.crt

openssl pkcs12 -export -out Energux.pkcs12 -in EnerguX-Server.crt -inkey EnerguX-Server.key

keytool -importkeystore -srckeystore EnerguX.pkcs12 -srcstoretype PKCS12 \
	-destkeystore /usr/share/tomcat8/EnerguX.jks -deststoretype JKS

chown tomcat8:tomcat8 /usr/share/tomcat8/EnerguX.jks
```

Definir puertos de escucha

Editando el fichero de configuración global del servidor `/etc/tomcat8/server.xml`, haciendo que las secciones `<Conector />` queden como se muestra debajo.

```bash
cp /etc/tomcat8/server.xml{,.org}
nano /etc/tomcat8/server.xml
```
```xml
<Connector port="80" protocol="HTTP/1.1"
			connectionTimeout="20000"
			URIEncoding="UTF-8"
			enableLookups="false"
			redirectPort="443" />

<Connector port="443" protocol="HTTP/1.1"
			maxThreads="150" SSLEnabled="true"
			scheme="https" secure="true"
			clientAuth="false" sslProtocol="TLS"
			keystoreType="PKCS12"
			keystoreFile="/usr/share/tomcat7/EnerguX.jks"
			keystorePass="MyS3cr3tP@ssw0rd" />
```

Establecer que el servidor sólo acepte conexiones bajo protocolo seguro

Editar el fichero `/etc/tomcat8/web.xml` y agregar dentro de la sección `<web-app>` el siguiente contenido.

```bash
cp /etc/tomcat8/web.xml{,.org}
nano /etc/tomcat8/web.xml
```
```xml
<security-constraint>
	<web-resource-collection>
		<web-resource-name>HTTPSOnly</web-resource-name>
		<url-pattern>/*</url-pattern>
	</web-resource-collection>
	<user-data-constraint>
		<transport-guarantee>CONFIDENTIAL</transport-guarantee>
	</user-data-constraint>
</security-constraint>
```

Reiniciar el servicio `tomcat8` y probar accediendo al EnerguX a través de la URL `http://localhost/energux`.

## Definir aplicación por defecto

Si se desea que EnerguX sea la aplicación web por defecto de Tomcat, es decir que solo sea necesario teclear la dirección `http://localhost/` y no `http://localhost/energux`; se debe hacer lo siguiente:

```bash
cd /var/lib/tomcat8/webapps
mv ROOT/ ROOT_ORG/
mv energux/ ROOT/
systemctl restart tomcat8
```

## Realizar salvas automáticas de la base de datos

Opcionalmente se puede crear un script de salvas, usando el ejemplo que se muestra debajo o una versión personalizada.

```bash
nano /usr/local/bin/energux_db_backup.sh

#!/bin/bash
BDIR=/var/backups/energux_db/$(date +%Y)
FILENAME=energux_$(date +%d%m%Y).sql
if [ ! -d $BDIR/$(date +%B) ]; then
	mkdir -p $BDIR/$(date +%B)
fi
if [ -f $BDIR/$(date +%B)/$FILENAME ]; then
	rm $BDIR/$(date +%B)/$FILENAME | pg_dump energux -h localhost -E UTF8 -U postgres -w -v -f $BDIR/$(date +%B)/$FILENAME
else
	pg_dump energux -h localhost -E UTF8 -U postgres -w -v -f $BDIR/$(date +%B)/$FILENAME
fi
exit 0
```

Crear archivo `.pgpass` en el directorio `home` del usuario `root`

```bash
nano /root/.pgpass

localhost:5432:energux:postgres:passwd
```

* Asignar atributos de ejecución

```bash
chmod +x /usr/local/bin/energux_db_backup.sh
```

* Definir horario de ejecución

```bash
nano /etc/crontab

# EnerguX Database Daily Backup
@midnight	root 	energux_db_backup.sh > /dev/null 2>&1
```

* Reiniciar el servicio `cron`

```bash
systemctl restart cron
```

## Conclusiones

Aunque EnerguX utiliza versiones de `Apache Tomcat` un tanto obsoletas; es invaluable la importancia de un proyecto de esta embargadura dentro del sistema empresarial e incluso privado, en Cuba. Esperamos que este tutorial sirva de guía para su implementación en aquellos escenarios donde se lleve a cabo la migración de servicios a plataformas bajo software libre, apuesta hoy del país en la búsqueda de la independencia y soberanía tecnológicas.

## Referencias

* [Productos | Desoft - EnerguX](https://www.desoft.cu/es/productos/159)
* [Apache Tomcat 8 Tomcat Setup](https://tomcat.apache.org/tomcat-8.5-doc/index.html)
* [Apache Tomcat 8 Configuration Reference The HTTP Connector](https://tomcat.apache.org/tomcat-8.5-doc/config/http.html)
* [Apache Tomcat 8 SSL/TLS Configuration How-To](https://tomcat.apache.org/tomcat-8.5-doc/ssl-howto.html)
* [Run Tomcat on 80 Using Authbind in GCP](https://www.infiflex.com/run-tomcat-on-80-using-authbind-in-gcp)
