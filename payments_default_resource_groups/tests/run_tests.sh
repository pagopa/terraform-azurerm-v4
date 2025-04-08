#!/bin/bash

#########################################################################
# Script per eseguire i test del modulo Azure Resource Groups
#########################################################################
#
# DESCRIZIONE:
# Questo script automatizza l'esecuzione dei test Terraform per il modulo
# Azure Resource Groups. Verifica la creazione dei resource group,
# l'applicazione dei tag e la gestione dei lock.
#
# PREREQUISITI:
# - Terraform >= 1.3.0
# - Azure CLI installato e configurato
# - File backend.ini nella stessa directory
#
# UTILIZZO:
#   ./run_tests.sh         # Esegue tutti i test
#   ./run_tests.sh clean   # Pulisce l'ambiente di test
#
# ESEMPI:
#   1. Eseguire i test:
#      $ ./run_tests.sh
#
#   2. Pulire l'ambiente:
#      $ ./run_tests.sh clean
#
# NOTE:
# - Lo script verificherà automaticamente i prerequisiti
# - In caso di errore, verrà mostrato il punto esatto del fallimento
# - L'output usa i colori per una migliore leggibilità
#########################################################################

# Abilita il controllo degli errori
set -e

# Colori per l'output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per la gestione degli errori
handle_error() {
    echo -e "${RED}Errore nella linea $1${NC}"
    exit 1
}

# Imposta il gestore degli errori
trap 'handle_error $LINENO' ERR

# Funzione per la verifica dei prerequisiti
check_prerequisites() {
    echo "Verifico i prerequisiti..."

    # Verifica terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform non è installato${NC}"
        exit 1
    fi

    # Verifica Azure CLI
    if ! command -v az &> /dev/null; then
        echo -e "${RED}❌ Azure CLI non è installato${NC}"
        exit 1
    fi

    # Verifica backend.ini
    if [ ! -f "./backend.ini" ]; then
        echo -e "${RED}❌ File backend.ini non trovato${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Tutti i prerequisiti sono soddisfatti${NC}"
}

# Funzione per la pulizia
cleanup() {
    echo -e "${YELLOW}🧹 Pulizia dell'ambiente di test...${NC}"
    rm -rf .terraform* terraform.tfstate*
    echo -e "${GREEN}✅ Pulizia completata${NC}"
}

# Funzione principale per l'esecuzione dei test
run_tests() {
    echo -e "${YELLOW}🚀 Inizializzazione di Terraform...${NC}"
    terraform init

    echo -e "${YELLOW}▶️ Esecuzione dei test...${NC}"
    if terraform test; then
        echo -e "${GREEN}✅ Tutti i test sono passati con successo!${NC}"
        return 0
    else
        echo -e "${RED}❌ Alcuni test sono falliti${NC}"
        return 1
    fi
}

# Gestione dei parametri
case "${1:-}" in
    "clean")
        cleanup
        ;;
    "")
        check_prerequisites
        run_tests
        ;;
    *)
        echo -e "${RED}Comando non valido. Uso: $0 [clean]${NC}"
        exit 1
        ;;
esac
