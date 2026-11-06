# Instalación de Odoo 18 en Ubuntu Server

**Ciclo:** Desarrollo de Aplicaciones Multiplataforma (DAM)\
**Módulo:** Sistemas de Gestión Empresarial\
**Entorno:** Ubuntu Server, PostgreSQL, Python y Odoo 18\
**Modalidad:** Trabajo individual

------------------------------------------------------------------------

## Inicio 

En esta práctica vamos a instalar Odoo en un servidor Ubuntu. Lo haremos
directamente sobre Linux, sin Docker y sin entorno gráfico. Es decir,
trabajaremos desde la terminal durante todo el proceso.

La idea no es que usemos comandos sin más.
Estamos instalando, para qué sirve cada componente y cómo comprobar que
todo ha quedado funcionando. Si aparece un error, no paséis al siguiente
apartado sin intentar entender qué ha ocurrido.

Al terminar, deberéis poder entrar en Odoo desde el navegador de otro
ordenador de la red y explicar, al menos por encima, cómo se comunican
la aplicación y la base de datos.

### ¿Qué necesitamos?

-   Un servidor con Ubuntu Server instalado y actualizado.
-   Acceso al servidor con un usuario que tenga permisos `sudo`.
-   Conexión a Internet para descargar Odoo y sus dependencias.
-   Otro ordenador desde el que podamos probar el acceso a Odoo.
-   Una dirección IP del servidor accesible desde ese ordenador.

> **Una recomendación:** si estáis trabajando con una máquina virtual,
> comprobad que la configuración de red permite que vuestro ordenador
> acceda a ella. Si la red no está bien configurada, Odoo puede estar
> funcionando perfectamente y, aun así, no podréis abrirlo desde el
> navegador.

------------------------------------------------------------------------

## 1. Qué vamos a instalar y para qué sirve cada cosa

Antes de empezar con los comandos, vamos a situar las piezas:

  -----------------------------------------------------------------------
  Componnte                          Para qué lo necesitamos
  ----------------------------------- -----------------------------------
  Ubuntu Server                       Es el sistema operativo donde
                                      instalaremos y ejecutaremos Odoo.

  Python                              Odoo está desarrollado
                                      principalmente en Python.

  PostgreSQL                          Es el gestor de bases de datos que
                                      utilizará Odoo.

  Git                                 Lo usaremos para descargar el
                                      código fuente de Odoo.

  systemd                             Se encargará de iniciar, detener y
                                      supervisar el servicio Odoo.

  Odoo                                Es el ERP que vamos a dejar
                                      instalado y accesible desde la red.
  -----------------------------------------------------------------------

La instalación quedará organizada de esta manera:

``` text
ORDENADOR DEL USUARIO
        |
     Navegador
        |
 http://IP-DEL-SERVIDOR:8069
        |
   UBUNTU SERVER
        |
      ODOO
        |
    POSTGRESQL
        |
  Bases de datos
```

Cuando un usuario entra desde el navegador, no está ejecutando Odoo en
su ordenador. El navegador se comunica con la aplicación que está
funcionando en el servidor. Odoo, a su vez, consulta y guarda la
información en PostgreSQL.

**Quedaos con esta idea:** Odoo es la aplicación; PostgreSQL guarda sus
datos; Ubuntu Server mantiene todo funcionando.

------------------------------------------------------------------------

## 2. Actualizar Ubuntu e instalar herramientas

Lo primero es actualizar la información de los repositorios:

``` bash
sudo apt update
```

Después instalamos las actualizaciones disponibles:

``` bash
sudo apt upgrade -y
```

Ahora instalamos los paquetes que necesitaremos durante la práctica:

``` bash
sudo apt install git python3 python3-pip python3-venv python3-dev \
build-essential wget curl nano postgresql postgresql-client \
libpq-dev node-less npm -y
```

No hace falta memorizar ahora todos los paquetes. Lo importante es saber
que estamos preparando el servidor para poder descargar el código de
Odoo, ejecutar Python, instalar sus bibliotecas y utilizar PostgreSQL.

Podemos comprobar la versión de Python:

``` bash
python3 --version
```

Y comprobar el estado de PostgreSQL:

``` bash
sudo systemctl status postgresql
```

Si PostgreSQL no estuviera iniciado, ejecutad:

``` bash
sudo systemctl enable --now postgresql
```

`enable` hace que el servicio se inicie automáticamente cuando arranque
el servidor, y `--now` lo inicia en este momento.

> **Ojo:** si el comando `status` abre una pantalla con información,
> podéis salir pulsando `q`.

------------------------------------------------------------------------

## 3. Preparar PostgreSQL

Odoo necesita una base de datos para guardar la información de las
empresas, los usuarios, los productos, las facturas y el resto de datos
que gestionaremos desde el ERP.

Vamos a crear un usuario de PostgreSQL llamado `odoo`:

``` bash
sudo -u postgres createuser -s odoo
```

Comprobamos que se ha creado:

``` bash
sudo -u postgres psql -c "\du"
```

Deberíais ver el rol `odoo` en el listado.

El comando anterior lo crea inicialmente con permisos de superusuario.
No es buena idea dejar esos permisos más amplios de lo necesario, así
que vamos a ajustarlos:

``` bash
sudo -u postgres psql -c "ALTER ROLE odoo WITH NOSUPERUSER CREATEDB NOCREATEROLE;"
```

Con esto quitamos el permiso de superusuario y permitimos que el rol
pueda crear bases de datos, algo que Odoo necesita para crear nuevas
bases de datos desde su pantalla de administración.

### Una aclaración importante

En esta práctica vamos a tener dos usuarios llamados `odoo`, pero no son
exactamente el mismo:

-   El usuario `odoo` de Linux será el que ejecute el programa.
-   El rol `odoo` de PostgreSQL será el que se conecte a la base de
    datos.

Son cuentas de sistemas distintos. Que tengan el mismo nombre nos
facilita la configuración, pero no las convierte en una única cuenta.

------------------------------------------------------------------------

## 4. Crear un usuario Linux para Odoo

No vamos a ejecutar Odoo con nuestro usuario personal ni con `root`. Es
preferible que cada servicio tenga su propio usuario, con los permisos
que necesita.

Creamos el usuario y su grupo:

``` bash
sudo adduser --system --home=/opt/odoo --group odoo
```

Los archivos de la aplicación estarán dentro de `/opt/odoo`.

Podemos comprobar que se ha creado el directorio:

``` bash
ls -ld /opt/odoo
```

El directorio `/opt` se utiliza habitualmente para instalar aplicaciones
adicionales. Así mantenemos los archivos de Odoo separados de los
archivos personales de los usuarios.

------------------------------------------------------------------------

## 5. Descargar el código de Odoo

Vamos a descargar la rama 18.0 del repositorio oficial de Odoo. Lo
haremos con Git y como usuario `odoo`, para que los archivos queden bajo
su propiedad:

``` bash
sudo -u odoo git clone --branch 18.0 --depth 1 --single-branch https://github.com/odoo/odoo.git /opt/odoo/odoo

```

El comando puede tardar un poco, dependiendo de la conexión.

Cuando termine, comprobamos el contenido:

``` bash
ls /opt/odoo/odoo
```

Entre otros archivos y carpetas, deberíais encontrar:

-   `odoo-bin`
-   `addons`
-   `requirements.txt`
-   `setup`

El archivo `odoo-bin` es el punto de entrada que utilizaremos para
arrancar Odoo. El archivo `requirements.txt` contiene la lista de
dependencias Python que necesita el proyecto.

> **En clase:** cuando descargamos un proyecto con Git, normalmente
> estamos obteniendo su código fuente. No es lo mismo que instalar una
> aplicación desde una tienda de software. Más adelante, cuando
> trabajéis con vuestros propios proyectos, utilizaréis Git de forma
> habitual.

------------------------------------------------------------------------

## 6. Crear un entorno virtual e instalar las dependencias

Odoo necesita distintas bibliotecas de Python. Para no mezclarlas con
las que utiliza el propio sistema operativo, vamos a crear un entorno
virtual.

Lo creamos dentro de `/opt/odoo`:

``` bash
sudo -u odoo python3 -m venv /opt/odoo/venv
```

Actualizamos las herramientas de instalación de Python:

``` bash
sudo -u odoo /opt/odoo/venv/bin/pip install --upgrade pip wheel setuptools
```

Instalamos las dependencias que aparecen en el archivo
`requirements.txt`:

``` bash
sudo -u odoo /opt/odoo/venv/bin/pip install -r /opt/odoo/odoo/requirements.txt
```

Este último paso puede tardar varios minutos. Es normal que aparezcan
bastantes líneas en pantalla.

### ¿Por qué usamos un entorno virtual?

Imaginad que en el mismo servidor tenemos dos aplicaciones Python y cada
una necesita una versión distinta de una biblioteca. Si instalamos todas
las dependencias globalmente, pueden aparecer conflictos.

Con un entorno virtual, cada proyecto mantiene sus propias bibliotecas.
En nuestro caso, Odoo utilizará el Python que está en:

``` text
/opt/odoo/venv/
```

Por eso, cuando arranquemos Odoo, no utilizaremos simplemente `python3`,
sino el intérprete de ese entorno virtual.

------------------------------------------------------------------------

## 7. Crear el archivo de configuración

Odoo necesita saber cómo conectarse a PostgreSQL, dónde están sus
módulos y en qué puerto debe escuchar.

Vamos a guardar esos datos en `/etc/odoo.conf`:

``` bash
sudo nano /etc/odoo.conf
```

Escribimos esta configuración:

``` ini
[options]

admin_passwd = CAMBIA_ESTA_CLAVE_MAESTRA

db_host = False
db_port = False
db_user = odoo
db_password = False

addons_path = /opt/odoo/odoo/addons

logfile = /var/log/odoo/odoo.log

http_port = 8069
http_interface = 0.0.0.0
```

**No dejéis la contraseña de ejemplo.** Cambiad
`CAMBIA_ESTA_CLAVE_MAESTRA` por una contraseña segura. Esta es la
contraseña maestra de administración de bases de datos de Odoo; no es la
contraseña con la que iniciaréis sesión en la aplicación.

Guardamos con `Ctrl + O`, pulsamos `Enter` y salimos con `Ctrl + X`.

### ¿Qué significan las opciones principales?

  -----------------------------------------------------------------------
  Opción                              Qué indica
  ----------------------------------- -----------------------------------
  `admin_passwd`                      Contraseña maestra para las
                                      operaciones de administración de
                                      bases de datos.

  `db_host`                           Servidor donde está PostgreSQL.

  `db_port`                           Puerto de PostgreSQL.

  `db_user`                           Rol de PostgreSQL que utilizará
                                      Odoo.

  `db_password`                       Contraseña del rol, si se utiliza
                                      autenticación por contraseña.

  `addons_path`                       Ruta donde están los módulos de
                                      Odoo.

  `logfile`                           Archivo donde se guardarán los
                                      registros.

  `http_port`                         Puerto web de Odoo.

  `http_interface`                    Interfaz de red en la que escuchará
                                      Odoo.
  -----------------------------------------------------------------------

En esta configuración, `db_host = False` indica que se utilizará una
conexión local mediante socket Unix. Para que funcione, PostgreSQL debe
tener una regla de autenticación local compatible con el usuario Linux
`odoo` y el rol PostgreSQL `odoo` (por ejemplo, autenticación `peer`).

Ajustamos los permisos del archivo:

``` bash
sudo chown root:odoo /etc/odoo.conf
sudo chmod 640 /etc/odoo.conf
```

Creamos la carpeta donde Odoo guardará sus registros:

``` bash
sudo mkdir -p /var/log/odoo
sudo chown odoo:odoo /var/log/odoo
```

`chown` cambia el propietario y el grupo. `chmod 640` permite que `root`
lea y escriba, que el grupo `odoo` lea y que el resto de usuarios no
tenga acceso.

------------------------------------------------------------------------

## 8. Configurar Odoo como servicio de Linux

Podríamos arrancar Odoo ejecutando un comando en la terminal, pero no
queremos depender de tener una sesión abierta. Queremos que Ubuntu se
encargue de iniciar y supervisar la aplicación.

Para ello vamos a crear un servicio de `systemd`.

Creamos el archivo:

``` bash
sudo nano /etc/systemd/system/odoo.service
```

Pegamos lo siguiente:

``` ini
[Unit]
Description=Odoo 18
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
User=odoo
Group=odoo

ExecStart=/opt/odoo/venv/bin/python /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf

StandardOutput=journal
StandardError=journal

Restart=always

[Install]
WantedBy=multi-user.target
```

Guardamos y salimos de Nano.

Ahora tenemos que informar a `systemd` de que hemos creado un servicio
nuevo:

``` bash
sudo systemctl daemon-reload
```

Lo configuramos para que arranque automáticamente al iniciar Ubuntu:

``` bash
sudo systemctl enable odoo
```

Y lo arrancamos ahora:

``` bash
sudo systemctl start odoo
```

### ¿Qué hace este archivo?

-   `Description`: describe el servicio.
-   `Requires` y `After`: declaran la dependencia de PostgreSQL y el
    orden de inicio.
-   `User` y `Group`: indican con qué usuario y grupo se ejecutará Odoo.
-   `ExecStart`: contiene el comando que arranca Odoo.
-   `Restart`: indica que systemd debe intentar reiniciar el servicio si
    el proceso termina.

Fijaos especialmente en `ExecStart`: estamos utilizando el Python del
entorno virtual y el archivo `odoo-bin` que descargamos antes. También
le indicamos dónde está el archivo de configuración.

------------------------------------------------------------------------

## 9. Comprobar que Odoo está funcionando

Consultamos el estado del servicio:

``` bash
sudo systemctl status odoo
```

Si todo ha ido bien, debería aparecer:

``` text
Active: active (running)
```

Eso indica que el servicio está en ejecución.

Si aparece `failed` o no arranca, no sigáis como si nada. Consultad los
registros:

``` bash
sudo journalctl -u odoo -n 50 --no-pager
```

También podemos consultar el archivo de log que configuramos:

``` bash
sudo tail -f /var/log/odoo/odoo.log
```

Para salir de la vista de registros, pulsad `Ctrl + C`. Esto no detiene
Odoo.

> **Consejo:** cuando algo no funciona en un servidor, acostumbrad a
> mirar primero el estado del servicio y después sus registros. El
> mensaje de error suele dar una pista bastante clara de dónde está el
> problema.

------------------------------------------------------------------------

## 10. Acceder a Odoo desde otro ordenador

Primero averiguamos la dirección IP del servidor:

``` bash
hostname -I
```

Por ejemplo, puede devolver:

``` text
192.168.1.150
```

La dirección real será la que aparezca en vuestro servidor. Desde otro
ordenador conectado a una red que pueda comunicarse con él, abrid el
navegador y escribid:

``` text
http://192.168.1.150:8069
```

Sustituid la IP del ejemplo por la vuestra.

Si utilizáis UFW y está activo, permitid el acceso al puerto 8069:

``` bash
sudo ufw allow 8069/tcp
```

Comprobad las reglas:

``` bash
sudo ufw status
```

Si no podéis acceder, comprobad también que Odoo está activo y que
escucha en el puerto correcto:

``` bash
sudo ss -tulpn | grep 8069
```

**Importante:** abrir el puerto en UFW no garantiza por sí solo que el
acceso funcione. La máquina virtual, el router o la red del centro
también deben permitir la comunicación entre los equipos.

> **Fijaos en esto:** el servidor no necesita tener instalado un
> navegador ni un escritorio gráfico. El navegador está en el ordenador
> del usuario. El servidor se limita a ejecutar Odoo y responder a las
> peticiones que recibe.

------------------------------------------------------------------------

## 11. Crear la primera base de datos

Si la instalación está funcionando, al entrar en la dirección del
servidor aparecerá la pantalla de gestión de bases de datos de Odoo.

Podéis crear una base de datos de prueba con estos datos:

  Campo           Ejemplo
  --------------- ---------------------------------------------
  Database Name   `empresa`
  Email           `admin@empresa.com`
  Password        Una contraseña que elijáis
  Language        Español
  Country         España
  Demo Data       Opcional, para disponer de datos de ejemplo

Pulsad **Create Database** y esperad a que termine el proceso.

Recordad que hay dos contraseñas distintas:

1.  La contraseña maestra `admin_passwd`, que configuramos en
    `/etc/odoo.conf`.
2.  La contraseña del usuario administrador de la base de datos de Odoo,
    que introducimos en el formulario.

No son intercambiables.

------------------------------------------------------------------------

## 12. Comandos que conviene tener a mano

Estos son los comandos que utilizaremos para administrar el servicio:

  Acción                              Comando
  ----------------------------------- -------------------------------
  Iniciar Odoo                        `sudo systemctl start odoo`
  Detener Odoo                        `sudo systemctl stop odoo`
  Reiniciar Odoo                      `sudo systemctl restart odoo`
  Consultar el estado                 `sudo systemctl status odoo`
  Activar el arranque automático      `sudo systemctl enable odoo`
  Desactivar el arranque automático   `sudo systemctl disable odoo`
  Consultar registros                 `sudo journalctl -u odoo -f`

Un detalle: detener o reiniciar el servicio no elimina las bases de
datos. Los datos están almacenados en PostgreSQL.

------------------------------------------------------------------------

## 13. Problemas habituales y cómo investigarlos

No siempre sale todo a la primera. Es parte del trabajo aprender a
localizar el problema.

### Odoo no arranca

Primero miramos el estado:

``` bash
sudo systemctl status odoo
```

Después consultamos los últimos mensajes:

``` bash
sudo journalctl -u odoo -n 50 --no-pager
```

Revisad especialmente si hay errores de configuración, permisos o
dependencias de Python.

### PostgreSQL no está iniciado

Comprobamos:

``` bash
sudo systemctl status postgresql
```

Si está detenido:

``` bash
sudo systemctl start postgresql
```

### No podemos abrir Odoo desde otro ordenador

Comprobad, por este orden:

``` bash
hostname -I
```

``` bash
sudo systemctl status odoo
```

``` bash
sudo ss -tulpn | grep 8069
```

``` bash
sudo ufw status
```

Aseguraos también de que el ordenador cliente puede comunicarse con la
IP del servidor.

### Fallan las dependencias de Python

Comprobad que existe el intérprete del entorno virtual:

``` bash
/opt/odoo/venv/bin/python --version
```

Si necesitáis repetir la instalación de dependencias:

``` bash
sudo -u odoo /opt/odoo/venv/bin/pip install -r /opt/odoo/odoo/requirements.txt
```

Si el error continúa, guardad el mensaje completo. No lo ocultéis ni lo
resolváis copiando comandos de Internet sin saber qué modifican.

------------------------------------------------------------------------

## 14. Trabajo que tenéis que entregar

Una vez terminada la instalación, preparad un documento PDF con los
siguientes apartados:

1.  Nombre y apellidos.
2.  Versión de Ubuntu Server utilizada.
3.  Breve explicación de la función de Odoo, Python y PostgreSQL.
4.  Capturas de los pasos principales de la instalación.
5.  Captura del estado del servicio Odoo.
6.  Captura del estado del servicio PostgreSQL.
7.  Captura del acceso a Odoo desde otro ordenador.
8.  Captura de la base de datos creada y de la pantalla principal de
    Odoo.
9.  Problemas que os hayan aparecido y cómo los habéis solucionado.

Las capturas deben permitir comprobar que habéis realizado vosotros el
procedimiento. No sirve entregar únicamente una imagen de Odoo abierto
en el navegador: también quiero ver parte del trabajo realizado en el
servidor.

------------------------------------------------------------------------

## 15. Comprobaciones prácticas

Realizad estas comprobaciones y responded a las preguntas.

### Actividad 1. Estado de Odoo

Ejecutad:

``` bash
sudo systemctl status odoo
```

**Pregunta:** ¿Qué significa que aparezca `active (running)`?

### Actividad 2. Estado de PostgreSQL

Ejecutad:

``` bash
sudo systemctl status postgresql
```

**Pregunta:** ¿Qué papel desempeña PostgreSQL en esta instalación?
¿Podría funcionar Odoo sin una base de datos?

### Actividad 3. Procesos

Ejecutad:

``` bash
ps aux | grep odoo
```

**Pregunta:** ¿Qué información muestra este comando? ¿Qué usuario está
ejecutando el proceso de Odoo?

### Actividad 4. Puerto de escucha

Ejecutad:

``` bash
sudo ss -tulpn | grep 8069
```

**Pregunta:** ¿Qué significa que Odoo esté escuchando en el puerto 8069?
¿Para qué sirve ese puerto?

### Actividad 5. Arranque automático

Reiniciad el servidor:

``` bash
sudo reboot
```

Cuando vuelva a estar disponible, conectad de nuevo y ejecutad:

``` bash
sudo systemctl status odoo
```

**Pregunta:** ¿Por qué Odoo vuelve a arrancar sin que tengamos que
ejecutar `systemctl start odoo`?

### Actividad 6. Acceso desde otro equipo

Entrad en Odoo desde otro ordenador utilizando la IP del servidor. Cread
una base de datos y comprobad que podéis acceder a la aplicación.

**Pregunta:** ¿Qué diferencia hay entre el ordenador cliente y el
servidor en esta instalación?

------------------------------------------------------------------------

## 16. Para terminar: pensad un momento en lo que habéis hecho

Responded con vuestras propias palabras. No quiero definiciones
copiadas: quiero comprobar que habéis entendido el procedimiento.

1.  ¿Qué diferencia hay entre instalar Odoo en un ordenador personal e
    instalarlo en un servidor?
2.  ¿Por qué necesita Odoo PostgreSQL?
3.  ¿Qué función tiene Python?
4.  ¿Para qué hemos utilizado Git?
5.  ¿Qué ventaja tiene crear un entorno virtual de Python?
6.  ¿Por qué hemos creado un usuario Linux específico para Odoo?
7.  ¿Qué es `systemd` y qué trabajo hace en esta práctica?
8.  ¿Qué ocurriría si no habilitásemos el arranque automático?
9.  ¿Por qué podemos utilizar Odoo desde otro ordenador aunque el
    servidor no tenga interfaz gráfica?
10. ¿Qué función tiene el puerto 8069?

------------------------------------------------------------------------

## Para cerrar la práctica

Hemos instalado una aplicación empresarial en Linux y la hemos dejado
funcionando como un servicio. Por el camino hemos tenido que preparar el
sistema, gestionar usuarios, instalar una base de datos, descargar
código, configurar Python y revisar los servicios.

Todo esto forma parte del trabajo que hay detrás de poner una aplicación
a disposición de sus usuarios. En Sistemas de Gestión Empresarial no
solo nos interesa saber utilizar un ERP: también viene bien conocer qué
necesita para funcionar y cómo se despliega en un servidor.

Mi consejo es que no os limitéis a copiar los comandos. Si sabéis
explicar qué hace cada parte y sois capaces de localizar un error cuando
algo falla, habréis aprovechado de verdad la práctica.

------------------------------------------------------------------------

## Documentación de consulta

-   [Documentación oficial de instalación de Odoo 18 desde código
    fuente](https://www.odoo.com/documentation/18.0/administration/on_premise/source.html)
-   [Código fuente oficial de Odoo 18 en
    GitHub](https://github.com/odoo/odoo/tree/18.0)

## Nota para el docente

Esta guía utiliza autenticación local de PostgreSQL mediante socket
Unix. La configuración de autenticación de PostgreSQL debe permitir que
el usuario Linux `odoo` se conecte como el rol PostgreSQL `odoo` (por
ejemplo, mediante una regla `peer` adecuada en `pg_hba.conf`). Si la
configuración del servidor es distinta, habrá que adaptar la
autenticación o configurar credenciales explícitas.

La guía está pensada para una práctica de laboratorio en una versión
compatible de Ubuntu Server. Antes de utilizar esta instalación en
producción, hay que configurar HTTPS mediante un proxy inverso, copias
de seguridad verificadas, restricciones de acceso y una política de
actualizaciones y mantenimiento. No se debe exponer directamente el
puerto 8069 a Internet sin las medidas de seguridad correspondientes.
