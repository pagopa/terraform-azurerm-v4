# Immagine per il Container App Job di sync ACR->ACR backup
FROM mcr.microsoft.com/azure-cli:2.65.0

RUN tdnf install -y jq && tdnf clean all

COPY acr-sync-entrypoint.sh /usr/local/bin/acr-sync-entrypoint.sh
RUN chmod +x /usr/local/bin/acr-sync-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/acr-sync-entrypoint.sh"]
