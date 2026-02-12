#!/bin/bash

# Script pour générer les dSYM manquants pour les frameworks CocoaPods
# Utilisé pour corriger l'erreur "archive did not include a dSYM for WebRTC.framework"

echo "🔍 Génération des dSYM pour les frameworks CocoaPods..."

# Chemin vers les frameworks
FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# Chemin vers le dossier dSYM
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}"

# Vérifier que les chemins existent
if [ -z "${FRAMEWORKS_PATH}" ] || [ -z "${DSYM_PATH}" ]; then
    echo "⚠️ Chemins non définis, skip génération dSYM"
    exit 0
fi

# Créer le dossier dSYM s'il n'existe pas
mkdir -p "${DSYM_PATH}" 2>/dev/null || true

# Vérifier si le dossier frameworks existe
if [ ! -d "${FRAMEWORKS_PATH}" ]; then
    echo "⚠️ Dossier frameworks non trouvé, skip génération dSYM"
    exit 0
fi

# Parcourir tous les frameworks
for FRAMEWORK in "${FRAMEWORKS_PATH}"/*.framework; do
    if [ -d "${FRAMEWORK}" ]; then
        FRAMEWORK_NAME=$(basename "${FRAMEWORK}" .framework)
        FRAMEWORK_EXECUTABLE="${FRAMEWORK}/${FRAMEWORK_NAME}"
        
        # Vérifier si le framework a un exécutable
        if [ -f "${FRAMEWORK_EXECUTABLE}" ]; then
            echo "📦 Traitement de ${FRAMEWORK_NAME}.framework..."
            
            # Générer le dSYM
            DSYM_FILE="${DSYM_PATH}/${FRAMEWORK_NAME}.framework.dSYM"
            
            if [ ! -d "${DSYM_FILE}" ]; then
                echo "   ✅ Génération du dSYM pour ${FRAMEWORK_NAME}..."
                dsymutil "${FRAMEWORK_EXECUTABLE}" -o "${DSYM_FILE}" 2>/dev/null || echo "   ⚠️ Échec génération dSYM pour ${FRAMEWORK_NAME} (ignoré)"
            else
                echo "   ⏭️  dSYM déjà existant pour ${FRAMEWORK_NAME}"
            fi
        fi
    fi
done

echo "✅ Génération des dSYM terminée!"
exit 0
