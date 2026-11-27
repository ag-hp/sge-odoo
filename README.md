# Guía Completa: Despliegue de Odoo 18, Módulos y Control de Versiones (Git)

Documentación integral del entorno de desarrollo para **Odoo 18** utilizando Docker, estructura de módulos personalizados y flujo de trabajo con GitHub.

## Enlaces y Recursos de Referencia

* [Material y Recursos del Proyecto (Google Drive)](https://drive.google.com/file/d/1S48aZfGXiQl1e24Bi2MvlXFyJK9WtkN-/view)
* [Documentación Oficial de Odoo 18 - Módulos](https://www.odoo.com/documentation/18.0/es_419/developer/reference/backend/module.html)

---

## Estructura del Proyecto

```text
sge-odoo/
├── README.md
├── commads.md
└── odoo18/
    ├── .vscode/
    │   └── settings.json
    ├── addons/
    ├── docs/
    ├── extra_addons/
    │   └── Odoo_DAM/
    │       └── 1ermodulo/
    │           ├── __init__.py
    │           ├── __manifest__.py
    │           └── administrador_notas/
    │               ├── __init__.py
    │               ├── __manifest__.py
    │               ├── models/
    │               │   ├── __init__.py
    │               │   ├── __manifest__.py
    │               │   └── grades_course.py
    │               ├── security/
    │               └── views/
    ├── odoo/
    │   └── odoo.conf
    ├── crear.sh
    └── docker-compose.yml
```

---

## 1. Despliegue y Gestión de Odoo 18 con Docker

### Preparación del entorno y scripts
```bash
# Crear la carpeta del proyecto y acceder a ella
mkdir odoo18
cd odoo18

# Dar permisos de ejecución al script de creación
chmod +x crear.sh

# Ejecutar el script de inicialización
./crear.sh

# Listar archivos y verificar permisos en el directorio actual
ls -l
```

### Gestión de contenedores (Docker Compose)
```bash
# Levantar los contenedores en segundo plano (modo detached)
docker compose up -d

# Levantar los contenedores en primer plano (para ver logs en tiempo real)
docker compose up

# Levantar los contenedores eliminando contenedores huérfanos antiguos
docker compose up -d --remove-orphans

# Detener y eliminar los contenedores definidos en el docker-compose.yml
docker compose down

# Listar todos los contenedores (activos y detenidos)
docker ps -a

# Listar únicamente los contenedores en ejecución
docker ps
```

### Eliminación forzada de contenedores y limpieza de volúmenes
```bash
# Forzar la eliminación de los contenedores específicos de Odoo y PostgreSQL
docker rm -f odoo
docker rm -f db

# Listar todos los volúmenes de Docker existentes
docker volume ls

# Eliminar volúmenes específicos de datos y addons de Odoo
docker volume rm odoo-data
docker volume rm odoo-db
docker volume rm odoo-addons
docker volume rm odoo_addons
docker volume rm odoo_extra_addons
docker volume rm odoo_odoo-data
docker volume rm odoo_odoo-db-data

# Eliminar todos los volúmenes locales que no estén siendo utilizados por ningún contenedor
docker volume prune
```

### Navegación útil en terminal
```bash
# Volver al directorio principal del usuario (/home/usuario)
cd

# Subir un nivel en la jerarquía de carpetas
cd ..

# Consultar el historial de comandos ejecutados
history
```

---

## 2. Estructura del Módulo Odoo (`__manifest__.py`)

Plantilla base del archivo manifiesto ubicado dentro de `extra_addons/Odoo_DAM/1ermodulo/__manifest__.py`:

```python
{
    'name': 'Modulo Marco',
    'version': '18.0.1.1',
    'summary': 'Este es mi primer Modulo de odoo',
    'description': """
    Es un modulo que quiere mostrar como odoo lo muestra en sus aplicaciones
    """,
    'author': 'Marco Zeta',
    'website': 'https://marcoZeta.com',
    'category': 'Uncategorized',
    'license': 'LGPL-3',
    'depends': [
        'base',
    ],
    'data': [
        # 'security/ir.model.access.csv',
        # 'views/views.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
}
```

---

## 3. Control de Versiones con Git y GitHub

### Archivo `.gitignore` recomendado
Crea un archivo llamado `.gitignore` en la raíz del repositorio para evitar subir archivos temporales de Python o los datos pesados de la base de datos de Docker:

```text
postgres_data/
__pycache__/
*.pyc
```

### Flujo de trabajo diario (subir cambios a GitHub)
Cada vez que realices modificaciones en el proyecto desde Visual Studio Code, ejecuta en la terminal:

```bash
# 1. Añadir todos los archivos nuevos o modificados
git add .

# 2. Guardar los cambios con un mensaje descriptivo
git commit -m "Descripción clara de los cambios realizados"

# 3. Subir los cambios al repositorio remoto en GitHub
git push
```

### Resolución de conflictos de sincronización (si Git rechaza el push)
Si se realizaron cambios directamente en la web de GitHub y el comando `git push` es rechazado:

```bash
# 1. Configurar Git para fusionar ramas por defecto
git config pull.rebase false

# 2. Descargar y fusionar los cambios remotos sin abrir el editor de texto
git pull origin main --no-edit

# 3. Subir los cambios locales fusionados
git push
```

---

<p align="center">
  <a href="https://github.com/ag-hp/dam.git"><img src="https://img.shields.io/badge/DESARROLLO_DE_APLICACIONES_MULTIPLATAFORMA-000000?style=for-the-badge&logo=github&logoColor=white&labelColor=000000" alt="Ver Repositorio Completo Desarrollo de Aplicaciones Multiplataforma"></a>
</p>
