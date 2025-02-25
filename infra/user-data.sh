#!/bin/bash

# Instalar ferramentas
sudo apt-get install git -y
sudo apt-get install curl -y
sudo apt-get install jq -y
sudo apt-get install vim -y

# Install k6
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update  -y
sudo apt-get install k6

# Baixaar os scripts de testes
git clone https://github.com/horadoqa/scripts-k6