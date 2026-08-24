# Sistema de Catraca com Reconhecimento Facial e RFID

## 📌 Sobre o Projeto

Este projeto consiste no desenvolvimento de um sistema de controle de acesso baseado em uma **catraca eletrônica**, utilizando múltiplos métodos de autenticação.

O sistema terá como principais formas de identificação:

- 👤 Reconhecimento facial
- 💳 Identificação por RFID
- 🔐 Validação dos dados do usuário
- 🚪 Controle de acesso à catraca

A proposta é desenvolver um sistema capaz de realizar a identificação do usuário de forma rápida e segura, permitindo o acesso somente quando uma autenticação válida for realizada.

O projeto utiliza uma arquitetura composta por **Raspberry Pi** e **ESP32**, integrando processamento, comunicação, identificação e controle dos componentes físicos.

---

## 🎯 Objetivos

### Objetivo Geral

Desenvolver um sistema de controle de acesso utilizando reconhecimento facial e RFID integrado a uma catraca eletrônica.

### Objetivos Específicos

- Implementar identificação de usuários por RFID;
- Implementar reconhecimento facial;
- Integrar os métodos de autenticação ao sistema de controle de acesso;
- Controlar o mecanismo da catraca;
- Realizar a comunicação entre Raspberry Pi e ESP32;
- Registrar e gerenciar os acessos realizados;
- Desenvolver uma arquitetura modular para facilitar futuras expansões.

---

## ⚙️ Funcionamento

O sistema contará com dois métodos principais de autenticação.

### 🔹 RFID

O usuário aproxima seu cartão ou chaveiro RFID do leitor.

O sistema realiza a leitura do identificador e verifica se o usuário está autorizado.

Caso a identificação seja válida, o acesso é liberado.

### 🔹 Reconhecimento Facial

Uma câmera será utilizada para capturar a imagem do usuário.

A Raspberry Pi realizará o processamento necessário para identificar o usuário através de suas características faciais.

Após a identificação, o sistema verificará se o usuário possui autorização para acessar o ambiente.

### 🔹 Controle da Catraca

Quando uma autenticação válida for realizada, o sistema enviará um comando para liberar a catraca.

O ESP32 será responsável pela comunicação com os componentes de controle e pelo acionamento do mecanismo físico.

---
