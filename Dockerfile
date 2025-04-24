# Use the official Directus image
FROM directus/directus:11.6.1

WORKDIR /directus
# Copier les répertoires personnalisés
COPY extensions /directus/extensions
COPY migrations /directus/migrations

# Exposer le port par défaut de Directus
EXPOSE 8055

