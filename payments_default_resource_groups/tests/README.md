# Test per il modulo Azure Resource Groups

Questo documento descrive come eseguire i test per il modulo Azure Resource Groups.

## Prerequisiti

- Terraform >= 1.3.0
- Azure CLI installato e configurato
- Accesso a una sottoscrizione Azure
- File `backend.ini` configurato con le credenziali appropriate

## Struttura dei Test

I test verificano:
1. Creazione dei resource group predefiniti (data, security, compute, identity)
2. Creazione di resource group aggiuntivi
3. Applicazione corretta dei tag
4. Funzionalità dei resource lock
5. Convenzioni di naming

## Come eseguire i test

Lo script `run_tests.sh` automatizza l'esecuzione dei test. È possibile utilizzarlo in diversi modi:

```bash
# Eseguire tutti i test
./run_tests.sh

# Pulire l'ambiente di test
./run_tests.sh clean
```

### Comandi disponibili

- `./run_tests.sh`: Inizializza Terraform ed esegue i test
- `./run_tests.sh clean`: Rimuove i file di stato di Terraform e pulisce l'ambiente

## Interpretazione dei risultati

- ✅ Verde: Test completati con successo
- ❌ Rosso: Test falliti

In caso di fallimento, controllare l'output per i dettagli dell'errore.

## Note importanti

- Assicurarsi di avere il file `backend.ini` configurato correttamente
- I test creano risorse reali in Azure, assicurarsi di pulire l'ambiente dopo i test
- Verificare di avere le permissioni necessarie sulla sottoscrizione Azure
