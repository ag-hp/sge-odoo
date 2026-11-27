#!/bin/bash

set -e
cd "$(dirname "$0")"
echo "Iniciando entorno Odoo 18..."

# Bloquear root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Ejecuta el script con tu usuario normal."
    exit 1
fi

# Crear directorios si no existen
mkdir -p odoo addons extra_addons postgres_data

# Permisos de escritura
for DIR in odoo addons extra_addons; do
    if [ ! -w "$DIR" ]; then
        echo "ERROR: No tienes permisos de escritura en $DIR."
        echo "Ejecuta: sudo chown -R $USER:$USER $DIR"
        exit 1
    fi
done

# Configuración de Docker Compose
docker compose config -q

docker compose up -d

echo "concluido!!!"
echo "Entorno Odoo 18 iniciado correctamente."
echo "Odoo: http://localhost:8069"
echo "PostgreSQL: localhost:5432"
