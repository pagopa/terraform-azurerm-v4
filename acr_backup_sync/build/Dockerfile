# Immagine per il Container App Job di sync ACR->ACR backup
FROM mcr.microsoft.com/azure-cli:2.65.0@sha256:25c626eccc4968ffb7749787dca59a3e9d86c26b4abd0a6e8c70fca14c782452

RUN tdnf install -y jq && tdnf clean all

COPY acr-sync-entrypoint.sh /usr/local/bin/acr-sync-entrypoint.sh
RUN chmod +x /usr/local/bin/acr-sync-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/acr-sync-entrypoint.sh"]
